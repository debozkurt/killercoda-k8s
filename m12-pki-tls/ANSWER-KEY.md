# M12 — PKI & TLS — Answer Key

> Self-grading reference. Work each scenario first, then check your diagnostic path against the canonical one here. Instructors running the lab live can read the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline, plus cert-manager, an internal CA, and an mTLS pair (`config-api` in `media`, `config-client` in `app-services`). Each break/fix mutates one field in one PKI layer; the base fleet is healthy.

## Lesson summary

M12 is about how workloads get a cryptographic identity (a certificate) and use it to talk securely, and about the one reflex that makes TLS tractable: **every TLS failure is one of three questions — issuance, identity, trust.** Was a cert *signed* (does its Secret exist)? Does it claim the *right name* (SANs)? Does the verifier *trust the signer* (the CA)? cert-manager automates issuance and renewal via the `Issuer` / `Certificate` / `CertificateRequest` CRDs; an internal CA (a SelfSigned bootstrap issuer → a CA `Certificate` → a CA `ClusterIssuer`) signs the fleet's east-west certs; and mutual TLS proves *both* ends. The `baseline/` tour reads the healthy chain end to end; the three break/fix scenarios each knock out exactly one layer:

- `breakfix-01-certificate-not-ready` — **issuance**: a `Certificate` with a bad `issuerRef` never issues, so its Secret is never written and the server Pod is stuck `ContainerCreating`.
- `breakfix-02-san-mismatch` — **identity**: a cert that issues fine but whose SANs omit the name clients dial, so the handshake fails hostname verification.
- `breakfix-03-trust-mismatch` — **trust**: a valid, correctly-named server cert the client rejects because it mounts the wrong CA bundle.

The reflexes to carry: a stuck Pod on a `tls` volume means climb to the `Certificate`, not debug the Pod; `no alternative certificate subject name matches` is identity (read the SANs); `unable to get local issuer certificate` is trust (read the client's CA) — and you never fix trust by disabling verification.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (cert-manager & the internal CA):** `kubectl get pods -n cert-manager` shows the three components (controller, webhook, cainjector) `Running`; `kubectl get clusterissuers` shows `selfsigned-bootstrap` (SelfSigned) and `polyphone-ca` (CA), both `Ready`; the CA `Certificate` `polyphone-internal-ca` is `Ready` and its key/cert live in a Secret only cert-manager reads. `openssl x509 -subject -issuer` on the CA cert shows identical subject and issuer — a self-signed root. Teaching point: an internal CA is a two-step chain because a root signs itself.
- **Step 2 (a Certificate becomes a Secret):** `config-api-tls` is `Ready`; its Secret is type `kubernetes.io/tls` with `tls.crt` / `tls.key` / `ca.crt`; `openssl x509 -ext subjectAltName` shows the three DNS forms of the Service. Teaching point: the Secret is the deliverable, and SANs are the identity.
- **Step 3 (mTLS):** an `exec`'d `curl` with `--cert`/`--key`/`--cacert` returns `config-api: mTLS OK, client=CN=config-client`; dropping `--cert`/`--key` returns `400 No required SSL certificate was sent`. Teaching point: mTLS is issuance + identity + trust, both directions; network reachability isn't identity.
- **Step 4 (expiry & renewal):** `.status.notAfter` and `.status.renewalTime` show the validity window and cert-manager's scheduled auto-renewal (⅔ of lifetime); `openssl x509 -dates` on the Secret matches. Teaching point: renewal is a controller loop, so alert on the cert's expiry, not on the loop firing.

---

## Break/fix 01 — Issuance: a Certificate that won't issue

**Symptom:** `config-api` in `media` is stuck `ContainerCreating`, `0/1`, and never serves HTTPS. The rest of the fleet is healthy.

**Root cause:** The `config-api-tls` `Certificate`'s `issuerRef` names `polyphone-ca-typo`, an issuer that doesn't exist. cert-manager has nothing to sign with, so the `Certificate` sits `Ready: False`, the `kubernetes.io/tls` Secret<sup><a href="https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets">[4]</a></sup> `config-api-tls` is **never written**, and the Pod that mounts that Secret can't start — a `FailedMount` for a Secret that isn't there<sup><a href="https://cert-manager.io/docs/concepts/">[1]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Stuck, not crashing — it can't even start
kubectl get pods -n media -l app=config-api               # ContainerCreating, 0/1

# 2. What is it waiting on? A Secret that doesn't exist
kubectl describe pod -n media -l app=config-api | sed -n '/Events:/,$p'
#    Warning FailedMount ... secret "config-api-tls" not found

# 3. That Secret is written by a Certificate — is it Ready?
kubectl get certificate config-api-tls -n media           # READY False

# 4. WHY isn't it? The reason is on the child CertificateRequest
kubectl describe certificaterequest -n media -l cert-manager.io/certificate-name=config-api-tls | sed -n '/Status:/,$p'
#    Referenced "ClusterIssuer" not found: ... "polyphone-ca-typo" not found

kubectl get clusterissuers                                # the real one is polyphone-ca
```

**Fix:** Repoint the `Certificate` at the real internal-CA issuer.

```bash
kubectl patch certificate config-api-tls -n media --type=merge \
  -p '{"spec":{"issuerRef":{"name":"polyphone-ca"}}}'
```

**Verify:**

```bash
kubectl wait --for=condition=Ready certificate/config-api-tls -n media --timeout=90s   # True
kubectl get secret config-api-tls -n media                                             # now exists
kubectl rollout restart deployment/config-api -n media                                 # nudge the stuck Pod
kubectl rollout status  deployment/config-api -n media --timeout=90s
```

**What this scenario tests:** Climbing the issuance ladder instead of debugging the Pod. Self-grading questions:

- Did the `FailedMount` send you to the *Secret*, and the missing Secret to the *Certificate*, rather than to the Pod's image or command?
- Did you read the `CertificateRequest` (not just the `Certificate`) to get the actual reason issuance failed<sup><a href="https://cert-manager.io/docs/troubleshooting/">[2]</a></sup>?
- Did you recognize that a `Ready: False` cert writes no Secret, so the Pod *couldn't* start — the two symptoms have one cause?

**Expected time:** 3–6 min once "stuck `tls` mount → climb to the Certificate" is a reflex; 10–20 min the first time (lost time goes to re-pulling the image or editing the Pod, which were never the problem).

**Production thinking:** A single wrong `issuerRef` in a manifest takes a service fully offline, and the failure surfaces as a stuck Pod that looks nothing like a cert problem. Two guards: an admission check (or CI lint) that every `issuerRef` resolves to an existing issuer before merge; and an alert on `Certificate` objects that are `Ready: False` for more than a few minutes, which catches issuance failures — bad issuer, RBAC on the issuer, an unreachable CA — before a rollout mounts the missing Secret.

---

## Break/fix 02 — Identity: a cert valid for the wrong name

**Symptom:** `config-api` is `Running 1/1`, its `Certificate` is `Ready`, the Secret exists — but `config-client`'s mTLS call fails: `curl: (60) SSL: no alternative certificate subject name matches target host name 'config-api.media.svc.cluster.local'`.

**Root cause:** The server cert's Subject Alternative Names list only `config-api-legacy.media.svc.cluster.local`, but clients reach the Service at `config-api.media.svc.cluster.local`. Modern TLS verifies the connection's target host against the cert's **SANs** (the Common Name doesn't count), so a valid, trusted cert is rejected because its identity doesn't cover the name dialed<sup><a href="https://cert-manager.io/docs/usage/certificate/">[3]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce — read WHICH check failed
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/
#    (60) ... no alternative certificate subject name matches target host name  → identity, not trust

# 2. The app is fine; a green Certificate says "issued", not "correct"
kubectl get pods -n media -l app=config-api               # Running 1/1
kubectl get certificate config-api-tls -n media           # READY True

# 3. Read the served cert's SANs, and the dnsNames driving them
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext subjectAltName                # DNS:config-api-legacy.media.svc.cluster.local
kubectl get certificate config-api-tls -n media -o jsonpath='{.spec.dnsNames}{"\n"}'
```

**Fix:** Put every name clients use back into `dnsNames`, let cert-manager reissue, and roll nginx so it loads the new cert.

```bash
kubectl patch certificate config-api-tls -n media --type=merge -p \
  '{"spec":{"dnsNames":["config-api.media.svc.cluster.local","config-api.media.svc","config-api"]}}'
kubectl wait --for=condition=Ready certificate/config-api-tls -n media --timeout=90s
kubectl rollout restart deployment/config-api -n media       # nginx loaded the OLD cert at startup
```

**Verify:**

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext subjectAltName                  # now includes config-api.media.svc.cluster.local
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/   # config-api: mTLS OK
```

**What this scenario tests:** Splitting a handshake failure into identity vs trust from the error text, and reading a cert's SANs. Self-grading questions:

- Did the error's wording (`subject name matches`, not `local issuer certificate`) tell you this was identity, not trust?
- Did you decode the served cert and compare its SANs to the exact name the client dialed, rather than assuming the `Ready` cert was correct?
- Did you fix `dnsNames` **and** roll the server (cert-manager reissues, but nginx won't reload a mounted cert on its own)?

**Expected time:** 3–6 min once "read the error, then read the SANs" is a reflex; 10–20 min the first time (lost time goes to restarting the healthy app or suspecting DNS/the Service).

**Production thinking:** A missing SAN is a deterministic bug that *looks* intermittent — same-namespace callers using the short name may pass while cross-namespace callers using the FQDN fail, or vice-versa, depending on which names made it into the cert. Generate `dnsNames` from the Service's real names (or let a mesh/ingress integration derive them) so the cert and the Service can't drift, and remember `CN` is legacy: put every name in the SANs.

---

## Break/fix 03 — Trust: the client trusts the wrong CA

**Symptom:** `config-api`'s cert is issued, `Ready`, and correctly named — but `config-client`'s mTLS call fails: `curl: (60) SSL certificate problem: unable to get local issuer certificate`.

**Root cause:** `config-client` mounts the wrong trust bundle. Its `/etc/tls/trust` volume points at `legacy-ca-bundle` — an unrelated CA (`polyphone-legacy-ca`) — while the server's cert is signed by `polyphone-internal-ca`. The client can't chain the server's cert up to any CA it holds, so it rejects a perfectly valid certificate. This is a *trust* failure, not a bad cert<sup><a href="https://cert-manager.io/docs/configuration/ca/">[5]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce — the error is trust, not identity
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/
#    (60) ... unable to get local issuer certificate   → the client doesn't trust the signer

# 2. Who signed the server's cert?
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -issuer                         # issuer=CN=polyphone-internal-ca

# 3. Which CA is the client actually trusting?
kubectl exec -n app-services deploy/config-client -- \
  openssl x509 -in /etc/tls/trust/ca.crt -noout -subject # subject=CN=polyphone-legacy-ca  ← mismatch

# 4. Where does the wrong bundle come from?
kubectl get deploy config-client -n app-services \
  -o jsonpath='{.spec.template.spec.volumes[?(@.name=="trust")].secret.secretName}{"\n"}'   # legacy-ca-bundle
```

**Fix:** Mount the correct trust bundle (the internal CA's public cert). A strategic-merge patch updates the `trust` volume by name and leaves the identity volume alone.

```bash
kubectl patch deployment config-client -n app-services -p \
  '{"spec":{"template":{"spec":{"volumes":[{"name":"trust","secret":{"secretName":"internal-ca-bundle"}}]}}}}'
kubectl rollout status deployment/config-client -n app-services --timeout=90s
```

**Verify:**

```bash
kubectl exec -n app-services deploy/config-client -- \
  openssl x509 -in /etc/tls/trust/ca.crt -noout -subject   # subject=CN=polyphone-internal-ca
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/   # config-api: mTLS OK
```

**What this scenario tests:** Recognizing a trust failure and fixing it by distributing the right CA — not by disabling verification. Self-grading questions:

- Did `unable to get local issuer certificate` read as *trust* (the client's CA), sending you to compare the server's *issuer* against the CA the client holds?
- Did you find the mismatch by reading both certs (`-issuer` on the server cert, `-subject` on the client's mounted CA), not by guessing?
- Did you fix it by mounting the correct CA bundle, and explicitly **not** by adding `--insecure` / `insecureSkipVerify`?

**Expected time:** 3–6 min once "trust error → compare issuer vs the client's CA" is a reflex; 10–20 min the first time (or 30 seconds and a security incident if you reach for `--insecure`).

**Production thinking:** `curl --insecure` makes this error vanish by making verification meaningless — the client will now accept *any* cert, including an attacker's, so a trust bug becomes a silent MITM hole. The real fix is trust *distribution*: get the correct `ca.crt` (public, safe to spread) to every client. Copy-per-namespace doesn't scale; **trust-manager** syncs a CA bundle into every namespace and lets you hold two CAs during a root rotation so the swap doesn't cause a fleet-wide outage. Ban `insecureSkipVerify` in review — a passing test with verification off is worse than a failing one.

## References

1. cert-manager — Concepts (Certificate, Issuer, CertificateRequest): https://cert-manager.io/docs/concepts/
2. cert-manager — Troubleshooting issuance: https://cert-manager.io/docs/troubleshooting/
3. cert-manager — Certificate dnsNames & SANs: https://cert-manager.io/docs/usage/certificate/
4. Kubernetes — TLS Secrets (`kubernetes.io/tls`): https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets
5. cert-manager — CA Issuer: https://cert-manager.io/docs/configuration/ca/
