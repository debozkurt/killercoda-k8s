# M12 — PKI & TLS — Answer Key

> Self-grading reference. Work each scenario first, then compare your diagnostic path with the canonical one here.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline, plus cert-manager, an internal CA, and an mTLS pair (`config-api` in `media`, `config-client` in `app-services`). Each break/fix changes one field in one PKI layer. The rest of the fleet is healthy.

## Lesson summary

M12 teaches one reflex: every TLS failure is one of three questions. Was a cert **issued**? Does it claim the right **identity**? Does the verifier **trust** the signer? cert-manager automates issuance and renewal through `Issuer`, `Certificate` and `CertificateRequest` objects. An internal CA signs the east-west certs, and mutual TLS (mTLS) checks both ends. The baseline reads the healthy chain. The five scenarios each break one link:

- `breakfix-01-certificate-not-ready` — **issuance**: a `Certificate` names an issuer that does not exist, so no Secret is written and the server Pod waits.
- `breakfix-02-san-mismatch` — **identity**: the cert issues, but its SANs omit the name clients dial.
- `breakfix-03-trust-mismatch` — **trust**: a valid server cert, rejected by a client that mounts the wrong CA.
- `breakfix-04-issuer-not-ready` — **issuance, one rung deeper**: the issuer exists but cannot load its signing Secret, so two Certificates fail together.
- `breakfix-05-client-cert-purpose` — **mTLS, server side**: the client cert carries the wrong Extended Key Usage, so the server refuses it.

Carry these reflexes. A Pod stuck on a `tls` volume means: climb to the `Certificate`. A handshake error means the client rejects the server: `subject name matches` is identity, `unable to get local issuer certificate` is trust. An HTTP error from the server means the server rejects the client, and its log says why. Never fix trust by disabling verification.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (cert-manager and the internal CA):** three Deployments run in `cert-manager` (controller, webhook, cainjector). `selfsigned-bootstrap` (SelfSigned) and `polyphone-ca` (CA) read Ready True. The CA `Certificate` `polyphone-internal-ca` is Ready, and its Secret lives in `cert-manager`. Subject and issuer match on the decoded CA cert: a self-signed root. Teaching point: an internal CA is a two-step chain because a root signs itself.
- **Step 2 (a Certificate becomes a Secret):** `config-api-tls` is Ready. The Secret has type `kubernetes.io/tls` with `tls.crt`, `tls.key` and `ca.crt`. Kubernetes requires only the first two<sup><a href="https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets">[4]</a></sup>. cert-manager adds `ca.crt` as a best guess at the issuing CA<sup><a href="https://cert-manager.io/docs/faq/">[7]</a></sup>. The SAN list shows the three DNS forms of the Service. `describe deployment` shows the `tls` volume mounting `config-api-tls`.
- **Step 3 (mTLS):** the call with `--cert`, `--key` and `--cacert` returns `config-api: mTLS OK, client=CN=config-client`. Without the client cert, nginx returns a 400 page: `No required SSL certificate was sent`. Teaching point: network reachability is not identity.
- **Step 4 (expiry and renewal):** `describe certificate` shows `Not Before`, `Not After` and `Renewal Time`. Renewal falls at two thirds of the lifetime by default<sup><a href="https://cert-manager.io/docs/usage/certificate/">[3]</a></sup>. The decoded cert shows the same dates. Teaching point: alert on the cert's expiry, not on the renewal loop.
- **Step 5 (delete the Secret):** the Secret returns within seconds with a new serial number, and `Revision` moves from 1 to 2. The running server still answers, because nginx keeps the cert it loaded at startup. Teaching point: the `Certificate` holds the intent, and the Secret is derived state.

---

## Break/fix 01 — Issuance: a Certificate that won't issue

**Symptom:** `config-api` in `media` shows `ContainerCreating`, 0/1, and never serves HTTPS. The rest of the fleet is healthy.

**Root cause:** The `config-api-tls` `Certificate` names the issuer `polyphone-ca-typo`, which does not exist. cert-manager has nothing to sign with. The `Certificate` stays Ready False, the `kubernetes.io/tls` Secret<sup><a href="https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets">[4]</a></sup> is never written, and the Pod that mounts it cannot start<sup><a href="https://cert-manager.io/docs/concepts/">[1]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Stuck, not crashing
kubectl get pods -n media -l app=config-api               # ContainerCreating, 0/1

# 2. What does it wait for? Read the Events at the bottom
kubectl describe pod -n media -l app=config-api
#    Warning FailedMount ... secret "config-api-tls" not found

# 3. A Certificate writes that Secret. Is it Ready?
kubectl get certificate config-api-tls -n media           # READY False
kubectl describe certificate config-api-tls -n media      # Events: issuing because the Secret does not exist

# 4. Why not? The reason lives on the child CertificateRequest
kubectl describe certificaterequest -n media
#    Message: Referenced "ClusterIssuer" not found: ... "polyphone-ca-typo" not found

kubectl get clusterissuers                                # the real one is polyphone-ca
```

**Fix:** Point the `Certificate` at the real issuer. cert-manager compares the open CertificateRequest with the spec, finds the old `issuerRef`, and creates a new request.

```bash
kubectl patch certificate config-api-tls -n media --type=merge \
  -p '{"spec":{"issuerRef":{"name":"polyphone-ca"}}}'
```

**Verify:**

```bash
kubectl wait --for=condition=Ready certificate/config-api-tls -n media --timeout=90s
kubectl get secret config-api-tls -n media                # exists now
kubectl rollout restart deployment/config-api -n media    # skips the kubelet's mount retry delay
kubectl rollout status deployment/config-api -n media --timeout=90s
```

**What this scenario tests:** climbing the issuance ladder instead of debugging the Pod. Self-grading questions:

- Did the `FailedMount` event send you to the Secret, and the missing Secret to the `Certificate`, not to the image or the command?
- Did you read the CertificateRequest, not only the `Certificate`, to find the reason<sup><a href="https://cert-manager.io/docs/troubleshooting/">[2]</a></sup>?
- Did you see that a Ready False cert writes no Secret, so one cause explains both symptoms?

**Expected time:** 3–6 minutes once "stuck `tls` mount, climb to the Certificate" is a reflex. First time: 10–20 minutes, mostly spent on the image and the command, which were never the problem.

**Production thinking:** One wrong `issuerRef` takes a service fully offline, and the failure looks like a Pod problem. Add a CI lint that every `issuerRef` resolves to an existing issuer before merge. Add an alert on `Certificate` objects that stay Ready False for more than a few minutes. That alert catches a bad issuer before a rollout mounts the missing Secret.

---

## Break/fix 02 — Identity: a cert valid for the wrong name

**Symptom:** `config-api` is Running 1/1, its `Certificate` is Ready, and its Secret exists. The mTLS call from `config-client` fails with `curl: (60) SSL: no alternative certificate subject name matches target host name 'config-api.media.svc.cluster.local'`.

**Root cause:** The cert lists one SAN, `config-api-legacy.media.svc.cluster.local`. Clients dial `config-api.media.svc.cluster.local`. A TLS client matches the dialed name against the SANs, so the client rejects a valid, trusted cert whose identity does not cover that name<sup><a href="https://cert-manager.io/docs/usage/certificate/">[3]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce and read WHICH check failed
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/
#    (60) ... no alternative certificate subject name matches  → identity, not trust

# 2. The app is fine. A Ready Certificate means issued, not correct.
kubectl get pods -n media -l app=config-api               # Running 1/1
kubectl get certificate config-api-tls -n media           # READY True

# 3. Read the served cert's SANs, then the spec that drives them
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext subjectAltName               # DNS:config-api-legacy.media.svc.cluster.local
kubectl describe certificate config-api-tls -n media      # Spec: Dns Names
```

**Fix:** Put every name clients use back into `dnsNames`. Let cert-manager reissue. Then roll nginx, which loaded the old cert at startup.

```bash
kubectl patch certificate config-api-tls -n media --type=merge -p \
  '{"spec":{"dnsNames":["config-api.media.svc.cluster.local","config-api.media.svc","config-api"]}}'
sleep 5
# Confirm with the SAN list. Ready can read True until cert-manager notices the edit.
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext subjectAltName
kubectl rollout restart deployment/config-api -n media
```

**Verify:**

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/   # config-api: mTLS OK
```

**What this scenario tests:** splitting a handshake failure into identity and trust from the error text, then reading the SANs. Self-grading questions:

- Did the wording (`subject name matches`, not `local issuer certificate`) tell you this was identity?
- Did you decode the served cert and compare its SANs with the exact name the client dialed, and not trust the Ready status?
- Did you confirm the reissue from the SAN list, and then roll the server?

**Expected time:** 3–6 minutes once "read the error, then read the SANs" is a reflex. First time: 10–20 minutes, mostly spent restarting a healthy app or suspecting DNS.

**Production thinking:** A missing SAN is a deterministic bug that looks intermittent. Same-namespace callers that use the short name can pass while cross-namespace callers that use the full name fail. Generate `dnsNames` from the Service's real names so the cert and the Service cannot drift. The Common Name does not carry identity: put every name in the SANs.

---

## Break/fix 03 — Trust: the client holds the wrong CA

**Symptom:** The server cert is issued, Ready and correctly named. The call from `config-client` fails with `curl: (60) SSL certificate problem: unable to get local issuer certificate`.

**Root cause:** `config-client` mounts `legacy-ca-bundle` for trust. That bundle holds `polyphone-legacy-ca`. The internal CA, `polyphone-internal-ca`, signed the server cert. The client cannot chain the server cert to any CA it holds, so it rejects a valid cert. This is a trust failure, not a bad cert<sup><a href="https://cert-manager.io/docs/configuration/ca/">[5]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce. The error is trust, not identity.
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/
#    (60) ... unable to get local issuer certificate

# 2. Who signed the server cert?
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -issuer                           # issuer=CN=polyphone-internal-ca

# 3. Which Secret does the client mount for trust? Read Volumes: → trust
kubectl describe deployment config-client -n app-services # SecretName: legacy-ca-bundle

# 4. Which CA is in that bundle? The client image has no openssl, so decode on the host.
kubectl get secret legacy-ca-bundle -n app-services -o jsonpath='{.data.ca\.crt}' | base64 -d \
  | openssl x509 -noout -subject                          # subject=CN=polyphone-legacy-ca  ← mismatch
```

**Fix:** Mount the correct trust bundle. A strategic-merge patch updates the `trust` volume by name and leaves the identity volume alone.

```bash
kubectl patch deployment config-client -n app-services -p \
  '{"spec":{"template":{"spec":{"volumes":[{"name":"trust","secret":{"secretName":"internal-ca-bundle"}}]}}}}'
kubectl rollout status deployment/config-client -n app-services --timeout=90s
```

**Verify:**

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/   # config-api: mTLS OK
```

**What this scenario tests:** recognizing a trust failure and fixing it with the right CA, not by disabling verification. Self-grading questions:

- Did `unable to get local issuer certificate` send you to compare the server's issuer with the CA the client holds?
- Did you find the mismatch by reading both certs, and not by guessing?
- Did you fix it with the correct bundle, and not with `--insecure` or `insecureSkipVerify`?

**Expected time:** 3–6 minutes once "trust error, compare the issuer with the client's CA" is a reflex. First time: 10–20 minutes, or 30 seconds and a security incident if you reach for `--insecure`.

**Production thinking:** `--insecure` makes the error vanish because verification no longer happens. The client then accepts any cert, including an attacker's. The real fix is trust distribution: get the correct `ca.crt`, which is public, to every client. Copying it per namespace does not scale. trust-manager syncs a bundle into every namespace<sup><a href="https://cert-manager.io/docs/trust/trust-manager/">[8]</a></sup>, and it holds two CAs during a root rotation so the swap causes no outage. Ban `insecureSkipVerify` in review.

---

## Break/fix 04 — Issuance, one rung deeper: an issuer that cannot sign

**Symptom:** `config-api` in `media` and `config-client` in `app-services` both sit in `ContainerCreating`. No manifest of either changed. `kubectl get certificate -A` shows both leaf Certificates Ready False.

**Root cause:** The `polyphone-ca` `ClusterIssuer` points its `secretName` at `polyphone-internal-ca-old`, a Secret that does not exist. cert-manager cannot load the CA key pair, so the issuer reports Ready False. Every request that references the issuer waits with `Referenced issuer does not have a Ready status condition`<sup><a href="https://cert-manager.io/docs/configuration/ca/">[5]</a></sup>. Both leaf Certificates share that issuer, so both fail.

**Diagnostic commands (the canonical path):**

```bash
# 1. Two failures that start together share a cause. Find what they share.
kubectl get pods -n media -l app=config-api               # ContainerCreating
kubectl get pods -n app-services -l app=config-client     # ContainerCreating
kubectl get certificate -A                                # both leaf certs Ready False, CA certs True

# 2. The CertificateRequest names the failing link
kubectl describe certificaterequest -n media
#    Message: Referenced issuer does not have a Ready status condition

# 3. Read the issuer
kubectl get clusterissuers                                # polyphone-ca READY False
kubectl describe clusterissuer polyphone-ca
#    Message: Error getting keypair for CA issuer: ... not found

# 4. Compare the Secret the issuer names with the Secrets that exist
kubectl get secrets -n cert-manager                       # polyphone-internal-ca exists
```

**Fix:** Name the real signing Secret. cert-manager requeues the pending requests when the issuer changes state.

```bash
kubectl patch clusterissuer polyphone-ca --type=merge \
  -p '{"spec":{"ca":{"secretName":"polyphone-internal-ca"}}}'
```

**Verify:**

```bash
kubectl get clusterissuers                                # polyphone-ca READY True
kubectl get certificate -A                                # both leaf certs Ready True
kubectl rollout restart deployment/config-api -n media
kubectl rollout restart deployment/config-client -n app-services
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/   # config-api: mTLS OK
```

**What this scenario tests:** reading one rung below the CertificateRequest, and treating simultaneous failures as one shared cause. Self-grading questions:

- Did two failures in two namespaces make you look for the object they share, and not fix them one at a time?
- Did you separate "the issuer name does not resolve" (scenario 01) from "the issuer resolves but is not Ready"?
- Did you fix the issuer once, and not edit either `Certificate`?

**Expected time:** 4–8 minutes once "failures that start together, find the shared object" is a reflex. First time: 15–25 minutes, usually spent debugging each Pod separately.

**Production thinking:** A `ClusterIssuer` is shared infrastructure. One bad edit blocks every issuance and every renewal that depends on it, and existing certs keep working until they expire. That delay hides the fault. Alert on any issuer with Ready False, not only on Certificates. Review issuer changes like a database migration, because the blast radius is the whole fleet.

---

## Break/fix 05 — mTLS server side: a client cert issued for the wrong purpose

**Symptom:** Both Pods are Running and both Certificates are Ready. The call from `config-client` returns an HTML page: `400 Bad Request`, `The SSL certificate error`. curl reports no handshake error.

**Root cause:** The `config-client-tls` `Certificate` lists `usages` of `server auth`, `digital signature` and `key encipherment`, and omits `client auth`. cert-manager issues exactly the usages the spec lists<sup><a href="https://cert-manager.io/docs/usage/certificate/">[3]</a></sup>. The cert's Extended Key Usage says server authentication only. nginx, set to require a client certificate<sup><a href="https://nginx.org/en/docs/http/ngx_http_ssl_module.html">[6]</a></sup>, verifies the cert for client use and rejects it. The signer and the name are correct. The purpose is wrong.

**Diagnostic commands (the canonical path):**

```bash
# 1. Read who answers. An HTTP reply means the TLS channel opened.
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/
#    400 Bad Request: The SSL certificate error  → the server rejected the client cert

# 2. Ask the server why. The lab logs this at info level; nginx hides it by default.
kubectl logs -n media deploy/config-api --tail=5
#    client SSL certificate verify error: (26:unsuitable certificate purpose)

# 3. Read the client cert's purpose
kubectl get secret config-client-tls -n app-services -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext extendedKeyUsage             # TLS Web Server Authentication

# 4. Find what drives it
kubectl describe certificate config-client-tls -n app-services   # Spec: Usages lists server auth
```

**Fix:** Restore `client auth`. cert-manager compares the spec with the current request and reissues.

```bash
kubectl patch certificate config-client-tls -n app-services --type=merge \
  -p '{"spec":{"usages":["client auth","digital signature","key encipherment"]}}'
sleep 5
kubectl get secret config-client-tls -n app-services -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext extendedKeyUsage             # TLS Web Client Authentication
kubectl rollout restart deployment/config-client -n app-services   # skips the kubelet's refresh delay
```

**Verify:**

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/
#    config-api: mTLS OK, client=CN=config-client
```

**What this scenario tests:** reading who rejects in mTLS, and separating three checks: signer, name and purpose. Self-grading questions:

- Did an HTTP error from the server, with no curl handshake error, tell you the server rejected the client?
- Did you read the server's log, and then decode the client cert's Extended Key Usage?
- Did you fix the `Certificate` spec, and not loosen the server's verification?

**Expected time:** 4–8 minutes once "HTTP error means the server judged me, read its log" is a reflex. First time: 15–25 minutes, usually spent on the client's trust bundle, which was fine.

**Production thinking:** The default `usages` of a cert-manager `Certificate` include `server auth` and omit `client auth`. A client identity copied from a server template fails exactly like this. Set `usages` explicitly in every client template. Keep server log levels high enough to record client-cert failures, because the default level hides the one line that names the cause.

## References

1. cert-manager — Concepts (Certificate, Issuer, CertificateRequest): https://cert-manager.io/docs/concepts/
2. cert-manager — Troubleshooting issuance: https://cert-manager.io/docs/troubleshooting/
3. cert-manager — Certificate usage (dnsNames, usages, renewal): https://cert-manager.io/docs/usage/certificate/
4. Kubernetes — TLS Secrets (`kubernetes.io/tls`): https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets
5. cert-manager — CA Issuer: https://cert-manager.io/docs/configuration/ca/
6. nginx — ngx_http_ssl_module (`ssl_verify_client`): https://nginx.org/en/docs/http/ngx_http_ssl_module.html
7. cert-manager — FAQ (what `ca.crt` holds): https://cert-manager.io/docs/faq/
8. cert-manager — trust-manager: https://cert-manager.io/docs/trust/trust-manager/
