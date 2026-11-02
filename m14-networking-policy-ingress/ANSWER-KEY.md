# M14 — Networking II: Policy & Ingress — Answer Key

> Self-grading reference. Work each scenario first, then compare your diagnostic path with the canonical one here. An instructor who runs the lab live can read the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline. Each break/fix changes one policy or one Ingress field. Nothing else is broken. The network plugin enforces NetworkPolicy. Every test call comes from a throwaway `busybox` client.

## Lesson summary

M14 teaches two controls over traffic that a Service leaves open. **NetworkPolicy** isolates a pod for one direction at a time. Policies add up, both ends of a connection must allow it, and the network plugin enforces them. **Ingress** is a set of routing rules that stay inert until a controller claims them through an IngressClass.

The baseline shows both controls healthy. The five break/fix scenarios each break one link:

- `breakfix-01-networkpolicy-default-deny`: **a service that went dark.** A default-deny has no allow.
- `breakfix-02-networkpolicy-cross-namespace`: **an allow that allows nothing.** The peer is a bare `podSelector`.
- `breakfix-03-ingress-misrouting`: **a 503 with a healthy backend.** The rule names a port the Service does not expose.
- `breakfix-04-egress-dns-timeout`: **every lookup in a namespace fails.** An egress policy never allows DNS.
- `breakfix-05-ingress-404-pathtype`: **a 404 for a path the backend serves.** The rule uses `Exact`.

The reflexes: a timeout with healthy DNS, endpoints and Pods is a policy drop. A cross-namespace allow needs a `namespaceSelector`. A failed lookup next to a working ClusterIP call is an egress policy without a DNS allow. A `503` is a backend problem. A `404` is a rule problem.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (the policies):** `describe` on `default-deny-ingress` shows `PodSelector: <none> (Allowing the specific traffic to all pods in this namespace)` and `<none> (Selected pods are isolated for ingress connectivity)`. `allow-broker-from-app` selects `app=session-broker` and allows TCP 80 from the `app-services` namespace.<sup><a href="https://kubernetes.io/docs/concepts/services-networking/network-policies/">[1]</a></sup>
- **Step 2 (enforcement):** the call from `app-services` returns the nginx page. The call from `signaling` hangs and fails with `wget: download timed out`. If both calls succeed, the network plugin does not enforce policy.
- **Step 3 (peers):** `describe` shows `NamespaceSelector: kubernetes.io/metadata.name=app-services` under From. The namespace carries that label automatically.
- **Step 4 (Ingress):** the controller Pod runs in `ingress-nginx`, and the IngressClass `nginx` exists. `get ingress` shows CLASS `nginx` and an ADDRESS. The call with `Host: portal.polyphone.example` returns the nginx page. The call with an unknown host returns `404 Not Found`.<sup><a href="https://kubernetes.io/docs/concepts/services-networking/ingress/">[3]</a></sup>
- **Step 5 (guarantees):** `probe-demo` reads `1/1 Running` although the default-deny selects it, because the kubelet's probe comes from the Pod's own node. A call out of `media` succeeds, because `default-deny-ingress` isolates ingress only. After the learner applies `allow-broker-from-signaling`, the `signaling` call succeeds. After the learner deletes it, the call hangs again.

---

## Break/fix 01 — a default-deny with no allow

**Symptom:** `session-broker` in `media` is Running and Ready. Calls to it hang and end with `wget: download timed out`. Endpoints exist and DNS resolves.

**Root cause:** The only policy in `media` is `default-deny-ingress`. It selects every Pod and lists `Ingress` with no rules. Every Pod is isolated for ingress, and nothing allows a caller.<sup><a href="https://kubernetes.io/docs/concepts/services-networking/network-policies/">[1]</a></sup> The baseline had a second policy that allowed a source. That policy is missing.

**Diagnostic commands:**

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/   # hangs
kubectl get endpoints session-broker -n media                           # Pod IPs on :80
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-broker.media.svc.cluster.local                       # resolves
kubectl get networkpolicy -n media                                      # one policy
kubectl describe networkpolicy default-deny-ingress -n media
#   isolated for ingress, no allowed source
```

A timeout with a healthy name and healthy endpoints leaves the policy as the cause.

**Fix:** Add an allow. Keep the deny.

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: allow-session-broker-internal, namespace: media }
spec:
  podSelector: { matchLabels: { app: session-broker } }
  policyTypes: [Ingress]
  ingress:
    - from: [{ podSelector: {} }]
      ports: [{ protocol: TCP, port: 80 }]
YAML
```

**Verify:**

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/   # nginx page
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n signaling -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/   # still times out
```

**What this scenario tests:** the isolation model and the additive rule. Self-grading questions:

- Did you rule out DNS and endpoints before you named the policy?
- Did you add an allow instead of deleting the deny?
- Can you say why the second policy does not weaken the first?

**Expected time:** 4–7 minutes with the reflex. 15–25 minutes the first time, spent on the Service and the Pods.

**Production thinking:** Roll out a default-deny with its allows in one change. Review the allows against real traffic before you apply the deny. A namespace that loses traffic after a policy lands should send you to `kubectl get networkpolicy` before the application.

---

## Break/fix 02 — an allow that allows nothing

**Symptom:** A caller with the label `app=sip-app` in `app-services` times out against `session-broker` in `media`. A policy named `allow-broker-from-app` exists and names `sip-app`.

**Root cause:** The allow's `from` entry is a single `podSelector: { matchLabels: { app: sip-app } }`. A bare `podSelector` selects Pods in the policy's own namespace.<sup><a href="https://kubernetes.io/docs/concepts/services-networking/network-policies/">[1]</a></sup> `media` holds no `sip-app` Pod, so the peer matches an empty set. The default-deny drops the real caller.

**Diagnostic commands:**

```bash
kubectl run sip-app --rm -i --restart=Never --labels app=sip-app \
  --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/   # hangs
kubectl describe networkpolicy allow-broker-from-app -n media
#   From: PodSelector: app=sip-app      (no NamespaceSelector)
kubectl get pods -n media -l app=sip-app                                # none
kubectl get pods -n app-services -l app=sip-app                         # the real one
```

**Fix:** Add a `namespaceSelector` in the same list entry.

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: allow-broker-from-app, namespace: media }
spec:
  podSelector: { matchLabels: { app: session-broker } }
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector: { matchLabels: { kubernetes.io/metadata.name: app-services } }
          podSelector:       { matchLabels: { app: sip-app } }
      ports: [{ protocol: TCP, port: 80 }]
YAML
```

**Verify:**

```bash
kubectl run sip-app --rm -i --restart=Never --labels app=sip-app \
  --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/   # nginx page
kubectl run other --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/   # still times out
```

**What this scenario tests:** peer semantics and list shape. Self-grading questions:

- Did you test as the real caller, with its namespace and label?
- Can you explain why a bare `podSelector` matched nothing?
- Can you say what the policy allows when the two selectors sit in two list entries?

**Expected time:** 5–8 minutes with the reflex. 15–25 minutes the first time, spent re-reading a policy that "looks right".

**Production thinking:** The AND and OR difference is one dash of YAML and a security boundary. Run `kubectl describe` on every new policy and read the From section aloud. Test a denied caller as well as an allowed one, because a policy that allows too much passes the allowed test too.

---

## Break/fix 03 — a 503 with a healthy backend

**Symptom:** Requests for `portal.polyphone.example` return `503 Service Temporarily Unavailable`. The `portal-ui` Pods are Ready. The Service has endpoints. A direct call to the Service succeeds.

**Root cause:** The Ingress rule sends traffic to `portal-ui` port `8080`. The Service exposes only port `80`. The controller matched the rule, found no endpoints for that port, and answered `503`. Both the Ingress controller and the Service layer are healthy.

**Diagnostic commands:**

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: portal.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/       # 503
kubectl get endpoints portal-ui -n admin-portal                          # Pod IPs on :80
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 http://portal-ui.admin-portal.svc.cluster.local/ # nginx page
kubectl describe ingress portal -n admin-portal                          # Backends: portal-ui:8080
kubectl get svc portal-ui -n admin-portal                                # PORT(S): 80/TCP
```

**Sharp edge:** `kubectl describe ingress` can list Pod IPs next to `portal-ui:8080`. In the kubectl source, the Backends column matches endpoints by port name. This Service's port has no name, so the empty name matches the endpoint port and the list appears for any number. Compare the rule's number with the Service's `PORT(S)`. Do not read the parentheses as proof.

**Fix:** Point the rule at port `80`.

```bash
kubectl patch ingress portal -n admin-portal --type=json \
  -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port/number","value":80}]'
```

**Verify:** the call through the controller returns the nginx page.

**What this scenario tests:** reading `503` as a backend problem. Self-grading questions:

- Did you read the status code first and name the half that broke?
- Did you prove the backend healthy before you read the rule?
- Did you compare the rule's port with the Service's `PORT(S)`?

**Expected time:** 4–7 minutes with the reflex. 15–25 minutes the first time, spent on the Pods.

**Production thinking:** An Ingress inherits every Service failure. Alert on Services behind an Ingress that have zero ready endpoints. Lint manifests so that a rule's port names a port of the Service in the same change. Use a named port, so a renumbered Service port does not break the rule silently.

---

## Break/fix 04 — an egress policy that breaks DNS

**Symptom:** Name lookups from `media` fail with `wget: bad address`. CoreDNS Pods are Running. The same name resolves from `signaling`. A call by ClusterIP from `media` succeeds.

**Root cause:** `restrict-egress-to-namespace` isolates every Pod in `media` for egress and allows only `podSelector: {}`, the Pods of `media`. A DNS query goes to CoreDNS in `kube-system` on port 53.<sup><a href="https://kubernetes.io/docs/concepts/services-networking/network-policies/">[1]</a></sup> No rule allows it, so every lookup times out. The ClusterIP call worked because its backend Pod is in the allowed namespace.

**Diagnostic commands:**

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local./  # bad address
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n signaling -- \
  nslookup session-broker.media.svc.cluster.local.                       # resolves
kubectl get pods -n kube-system -l k8s-app=kube-dns                      # Running
kubectl get svc session-broker -n media                                  # read CLUSTER-IP
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://<CLUSTER-IP>/                             # nginx page
kubectl describe networkpolicy restrict-egress-to-namespace -n media
#   Policy Types: Egress; To: PodSelector: <none>  (only media)
```

The three tests split the cause: DNS is healthy, the network path works, and only the lookup fails.

**Why the trailing dot:** A short name tries every search domain from `resolv.conf` before it tries the name as given, and each try waits for a timeout. An absolute name (trailing dot) skips the search domains. The blocked query then fails in seconds instead of looking like a long hang.

**Fix:** Add an egress allow to the CoreDNS Pods. Keep the lockdown.

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: allow-dns-egress, namespace: media }
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector: { matchLabels: { kubernetes.io/metadata.name: kube-system } }
          podSelector:       { matchLabels: { k8s-app: kube-dns } }
      ports:
        - { protocol: UDP, port: 53 }
        - { protocol: TCP, port: 53 }
YAML
```

**Verify:**

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local./  # nginx page
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://portal-ui.admin-portal.svc.cluster.local./ # download timed out
```

The second call proves the lockdown survived: the name resolves and the connection to `admin-portal` stays blocked. The error text changed from `bad address` to `download timed out`.

**What this scenario tests:** egress isolation and the DNS dependency. Self-grading questions:

- Did you separate "DNS is down" from "the DNS query is blocked"?
- Did you use the ClusterIP call to prove the path works?
- Can you say why the allow needs both UDP and TCP?
- Can you say what would break if the allow listed only the namespace and not the Pod label?

**Expected time:** 5–8 minutes with the reflex. 20–30 minutes the first time, spent in CoreDNS logs and `kube-system`.

**Production thinking:** Every egress lockdown needs a DNS allow in the same change. Enumerate the workload's dependencies before you isolate egress: DNS, the metrics scraper, the tracing collector, the cloud metadata endpoint. If you run NodeLocal DNSCache, the DNS target is a node-local address and the allow differs. Test an egress policy on one workload before a namespace.

---

## Break/fix 05 — a 404 for a path the backend serves

**Symptom:** `portal.polyphone.example/` returns the nginx page. `portal.polyphone.example/index.html` returns `404 Not Found`. A direct call to the Service for `/index.html` succeeds.

**Root cause:** The rule has `path: /` with `pathType: Exact`. `Exact` matches the whole URL path, case sensitive, and nothing else.<sup><a href="https://kubernetes.io/docs/concepts/services-networking/ingress/">[3]</a></sup> A request for `/index.html` matches no rule, so the controller answers `404` from its default backend. The backend never sees the request.

**Diagnostic commands:**

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: portal.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/index.html   # 404
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 http://portal-ui.admin-portal.svc.cluster.local/index.html  # nginx page
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller --tail=30 | grep index.html
#   [upstream-default-backend]  no rule handled the request
kubectl get ingress portal -n admin-portal -o yaml
#   path: /   pathType: Exact
```

The same path works directly and fails through the Ingress, so the backend is not at fault. The default controller log format puts the upstream name in square brackets.<sup><a href="https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/log-format/">[6]</a></sup> A request that a rule handled names the namespace, Service and port there.

**Fix:** Change `pathType` to `Prefix`.

```bash
kubectl patch ingress portal -n admin-portal --type=json \
  -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/pathType","value":"Prefix"}]'
```

**Verify:** the call for `/index.html` through the controller returns the nginx page.

**What this scenario tests:** reading `404` as a rule problem and `pathType` semantics. Self-grading questions:

- Did you call the backend directly to rule it out?
- Did you read `pathType` and not only `path`?
- Can you say what `Prefix` with `/foo/bar` matches, and what it does not?

**Expected time:** 4–7 minutes with the reflex. 15–25 minutes the first time, spent in the portal Pods.

**Production thinking:** Default to `Prefix` and use `Exact` only when you mean it. Where two rules both match, the controller applies its own precedence, so avoid overlapping paths. A synthetic check that requests a deep link, and not only `/`, catches this class of fault. The Ingress API is frozen, and ingress-nginx ended best-effort maintenance in March 2026. Plan the move to another controller or the Gateway API before the next incident.<sup><a href="https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/">[4]</a></sup>

---

## References

1. Kubernetes — Network Policies: https://kubernetes.io/docs/concepts/services-networking/network-policies/
2. Kubernetes — Declare Network Policy (walkthrough): https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/
3. Kubernetes — Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
4. Kubernetes — Ingress Controllers: https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/
5. Kubernetes — Gateway API: https://kubernetes.io/docs/concepts/services-networking/gateway/
6. Ingress-NGINX — Log format: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/log-format/
7. Kubernetes — Debug Services: https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/
8. Ingress-NGINX — project repository (retirement notice): https://github.com/kubernetes/ingress-nginx
