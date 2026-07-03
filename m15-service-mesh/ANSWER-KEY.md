# M15 — Service Mesh — Answer Key

> Self-grading reference. Try each scenario first, then check your diagnostic path against the canonical one. Instructors running the lab live can use the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline plus Istio (minimal profile). The `media` namespace is labeled `istio-injection=enabled`, so its workloads run with an Envoy sidecar (`2/2`). A long-lived `mesh-client` pod originates in-mesh traffic via `kubectl exec`. `session-broker` is fronted by a VirtualService (route → `stable`, timeout, retries), a DestinationRule (subsets, connection pool, outlier detection, `tls: ISTIO_MUTUAL`), and a namespace-wide `STRICT` PeerAuthentication.

## Lesson summary

M15 adds a second dataplane inside the pod network: an Envoy sidecar beside each workload, configured by the istiod control plane. Three break/fix scenarios produce the **same client-visible `503`** from three different links in the mesh request path (listener → route → cluster → endpoint → mTLS):

- `breakfix-01-sidecar-not-injected` — the target has **no sidecar** (`1/1`), so it isn't in the mesh; callers' mTLS has nothing to terminate against
- `breakfix-02-virtualservice-subset` — the route targets a **subset with no pods**, so Envoy's cluster is empty (no healthy upstream)
- `breakfix-03-mtls-mode-mismatch` — the client is told to send **plaintext** while the server requires **mTLS**, so the server resets the connection

The through-line: **a mesh `503` with a healthy Service is not an app problem — it's a dataplane-config problem, and `istioctl` localizes it.** `kubectl get pods` distinguishes 01 (`1/1`) from 02/03 (`2/2`); `istioctl proxy-config endpoints` distinguishes 02 (empty cluster) from 03 (endpoints present)<sup><a href="https://istio.io/latest/docs/ops/diagnostic-tools/proxy-cmd/">[4]</a></sup>; reading PeerAuthentication against the DestinationRule confirms 03. The workloads are healthy in all three, which is itself the tell.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (the sidecar):** `kubectl get namespace media --show-labels` shows `istio-injection=enabled`. `kubectl get pods -n media` shows `session-broker`, `transcoder`, `media-engine-*`, and `mesh-client` at `2/2`; `signaling` pods are `1/1`. The `session-broker` pod's containers are `app` and `istio-proxy`, and `istioctl proxy-status` lists every media sidecar with `SYNCED` columns. Teaching point: mesh membership is per-pod, decided at admission.
- **Step 2 (traffic management):** the `session-broker` VirtualService routes to `subset: stable` with `timeout: 3s` and `retries`; the DestinationRule defines subsets `stable`/`canary`, a connection pool, and `outlierDetection` (the circuit breaker). `kubectl exec deploy/mesh-client -c curl -- curl ... http://session-broker.media/` returns `HTTP 200`. `istioctl proxy-config routes` on the client shows the compiled route. Teaching point: L7 rules are applied by the caller's Envoy.
- **Step 3 (mTLS):** `PeerAuthentication default` is `mtls.mode: STRICT`. The in-mesh `mesh-client` reaches `session-broker` (`200`); a throwaway plaintext client in `signaling` (no sidecar) is rejected. Teaching point: STRICT is enforced by the server's sidecar; only a caller presenting a valid mesh identity gets in.
- **Step 4 (reading Envoy config):** `istioctl proxy-status` shows `SYNCED`. `istioctl proxy-config clusters`/`endpoints`/`listeners`/`routes` on the `mesh-client` pod walk listener → route → cluster → endpoint; the `stable` cluster has endpoints, the `canary` cluster is empty. Teaching point: the compiled config is the ground truth you debug against.

---

## Break/fix 01 — Sidecar not injected

**Symptom:** Callers of `session-broker` in `media` get `HTTP 503`. Its Pod is `Running`/`Ready`, `kubectl get endpoints session-broker -n media` lists the Pod IP on `:80`, and DNS resolves. Nothing logs an error; the app container is serving.

**Root cause:** The `session-broker` Deployment's pod template carries `sidecar.istio.io/inject: "false"`, which overrides the namespace's `istio-injection=enabled` and admits the pod **without a sidecar** — it comes up `1/1` and is not in the mesh<sup><a href="https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/">[1]</a></sup>. Every caller's sidecar is told by the `session-broker` DestinationRule to originate `ISTIO_MUTUAL` mTLS. With no sidecar on `session-broker` to terminate that mTLS, the caller's Envoy can't complete the connection and returns `503`. The workload is healthy; only its mesh membership is missing.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce from the in-mesh client — a 503
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/   # 503

# 2. Rule out the Service layer — endpoints present, DNS resolves
kubectl get endpoints session-broker -n media                     # PodIP:80
kubectl exec -n media deploy/mesh-client -c curl -- nslookup session-broker.media

# 3. Count containers — the tell
kubectl get pods -n media                                         # session-broker is 1/1, siblings 2/2
istioctl proxy-status | grep session-broker                       # absent — no sidecar registered with istiod
kubectl get pod -n media -l app=session-broker -o yaml | grep -A2 'annotations:'
#    sidecar.istio.io/inject: "false"
```

**Fix:** Re-enroll the workload — set injection back on and let the Deployment roll a new, injected pod. Do **not** touch mTLS:

```bash
kubectl patch deployment session-broker -n media \
  -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"true"}}}}}'
kubectl rollout status deployment session-broker -n media
# or: kubectl edit deployment session-broker -n media  → delete the inject: "false" annotation
```

**Verify:**

```bash
kubectl get pods -n media -l app=session-broker                   # now 2/2
istioctl proxy-status | grep session-broker                       # now listed, SYNCED
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/   # 200
kubectl get peerauthentication default -n media -o jsonpath='{.spec.mtls.mode}{"\n"}'        # still STRICT
```

**What this scenario tests:** Reading `2/2` vs `1/1` as a mesh-membership check, and knowing a sidecar-less pod is entirely outside the mesh. Self-grading questions:

- Did you check the container count and `proxy-status` before assuming the app or the Service was broken?
- Did you connect "no sidecar" to "no mTLS terminator" as the reason for the `503`, rather than blaming the DestinationRule?
- Did you fix by **re-enrolling** the workload, leaving `STRICT` mTLS intact — not by weakening the server to accept plaintext?

**Expected time:** 3–6 min once the `2/2` reflex is automatic; 10–18 min the first time (lost time goes to restarting the healthy app or re-reading a Service that was never broken).

**Production thinking:** This ships whenever a workload is templated with injection disabled, or deployed into a namespace before it was labeled. The loud `503` here is a lucky consequence of the explicit `ISTIO_MUTUAL` DestinationRule; under *automatic* mTLS the same missing sidecar would silently downgrade the hop to plaintext — an unencrypted security hole with no error. Alert on it structurally: a check that every pod in a meshed namespace is `2/2`, and mesh telemetry showing the workload is absent, catch it before a caller does.

---

## Break/fix 02 — VirtualService subset

**Symptom:** `session-broker` returns `HTTP 503`, but every `media` pod is `2/2` and in the mesh (`istioctl proxy-status` lists `session-broker` as `SYNCED`), the Service has endpoints, and mTLS is healthy. The workload is fine.

**Root cause:** The `session-broker` VirtualService routes to `subset: canary`. The DestinationRule defines `canary` as `labels: { version: canary }` — a version nobody deployed — so istiod compiles it into an Envoy cluster (`outbound|80|canary|session-broker.media.svc.cluster.local`) with **zero endpoints**. The route matches, Envoy selects the canary cluster, finds no healthy upstream, and returns `503`<sup><a href="https://istio.io/latest/docs/concepts/traffic-management/">[2]</a></sup>. The `stable` subset has the running pods; the route just aims at the empty one.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce — 503
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/   # 503

# 2. Rule out the workload — all 2/2, endpoints present (NOT breakfix-01)
kubectl get pods -n media
kubectl get endpoints session-broker -n media                     # PodIP:80

# 3. Follow the route in Envoy — the caller's sidecar routes it
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config routes "$POD" -n media --name 80 -o json | grep -i '"cluster"'
#    ...|canary|session-broker...   ← route targets the canary subset
istioctl proxy-config endpoints "$POD" -n media | grep session-broker
#    |stable| cluster has PodIPs:80 ; |canary| cluster is EMPTY

# 4. Confirm the source
kubectl get virtualservice session-broker -n media -o yaml | grep -A3 route:   # subset: canary
kubectl get pods -n media -l version=canary                       # none
```

**Fix:** Point the route at a subset that has pods (`stable`); the canary build doesn't exist to deploy:

```bash
kubectl patch virtualservice session-broker -n media --type=json \
  -p '[{"op":"replace","path":"/spec/http/0/route/0/destination/subset","value":"stable"}]'
# or: kubectl edit virtualservice session-broker -n media  → subset: canary → stable
```

**Verify:**

```bash
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config routes "$POD" -n media --name 80 -o json | grep -i '"cluster"'   # ...|stable|...
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/   # 200
```

**What this scenario tests:** Debugging a mesh `503` in the compiled Envoy config rather than in `kubectl get pods`, and knowing a subset can be valid but empty. Self-grading questions:

- Did the `2/2` pods steer you away from "the workload is down" and toward the route?
- Did you use `istioctl proxy-config routes` then `endpoints` to see the route landing on an empty cluster, instead of guessing?
- Did you connect the empty cluster to the VirtualService `subset` and the absence of `version: canary` pods?

**Expected time:** 4–8 min; 12–20 min the first time (lost time goes to re-checking healthy pods and endpoints instead of reading the route in Envoy).

**Production thinking:** This is the classic canary footgun: shift traffic to `version: canary` *before* the canary pods are `Ready`, and every routed request falls into an empty cluster. A VirtualService applying cleanly proves nothing about whether its subset has backends. Guard it by ordering the rollout (pods `Ready` before the traffic shift) and by testing routing with a real request in CI — and remember that a *partial* traffic split turns this into a *fractional* `503` that's easy to misread as flakiness.

---

## Break/fix 03 — mTLS mode mismatch

**Symptom:** `session-broker` returns `HTTP 503`. Every pod is `2/2`, the VirtualService routes to `stable`, `istioctl proxy-config endpoints` shows that cluster with healthy endpoints — and it still fails. Neither of the previous two causes applies.

**Root cause:** mTLS is configured on both sides and they **disagree**. The namespace `PeerAuthentication default` is `mtls.mode: STRICT` — `session-broker`'s sidecar accepts only mTLS. The `session-broker` DestinationRule sets `trafficPolicy.tls.mode: DISABLE` — callers' sidecars send **plaintext**. The caller sends plaintext into a server that rejects everything but mTLS; the server's sidecar resets the connection and the caller's Envoy returns `503`<sup><a href="https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/">[3]</a></sup>. Both ends are healthy and in the mesh; only the transport policies conflict.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce — 503
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/   # 503

# 2. Rule out 01 and 02 — sidecar present, route lands on endpoints
kubectl get pods -n media                                         # all 2/2 (not breakfix-01)
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config endpoints "$POD" -n media | grep 'session-broker' | grep ':80'   # stable has endpoints (not breakfix-02)

# 3. Read both halves of mTLS
kubectl get peerauthentication default -n media -o yaml | grep -A2 mtls:            # mode: STRICT   (server)
kubectl get destinationrule session-broker -n media -o yaml | grep -A2 'tls:'       # mode: DISABLE  (client)
#    server requires mTLS, client sends plaintext → mismatch
```

**Fix:** Align the client to the server. Raise the DestinationRule to `ISTIO_MUTUAL`; keep the server `STRICT`:

```bash
kubectl patch destinationrule session-broker -n media --type=json \
  -p '[{"op":"replace","path":"/spec/trafficPolicy/tls/mode","value":"ISTIO_MUTUAL"}]'
# or: kubectl edit destinationrule session-broker -n media  → mode: DISABLE → ISTIO_MUTUAL
# (removing the tls block entirely also works — automatic mTLS then negotiates it)
```

**Verify:**

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/   # 200
kubectl get peerauthentication default -n media -o jsonpath='{.spec.mtls.mode}{"\n"}'        # still STRICT
```

**What this scenario tests:** Recognizing mTLS as a two-sided contract and reading the server policy against the client policy. Self-grading questions:

- Did you rule out breakfix-01 (`2/2`) and breakfix-02 (endpoints present) before concluding "mTLS"?
- Did you read **both** the PeerAuthentication and the DestinationRule, rather than trusting either in isolation?
- Did you fix by raising the **client** to mTLS, keeping `STRICT`, instead of dropping the server to `PERMISSIVE` (which would silently make the hop plaintext)?

**Expected time:** 4–8 min; 12–20 min the first time (lost time goes to re-verifying healthy pods and routes, or to weakening the server to "make it work").

**Production thinking:** With no DestinationRule `tls` block, automatic mTLS would have negotiated this correctly — so an explicit `DISABLE` against a `STRICT` server is a self-inflicted mismatch, usually a copy-pasted rule or a leftover from a plaintext migration. Roll `STRICT` out the safe way: set `PERMISSIVE` first, let workloads gain sidecars and traffic become mTLS, confirm with telemetry, then flip to `STRICT`. And treat "fix by dropping to `PERMISSIVE`" as a regression, not a fix — it re-opens the plaintext path the mesh existed to close.

## References

1. Istio — Sidecar injection: https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/
2. Istio — Traffic management concepts (subsets, routing): https://istio.io/latest/docs/concepts/traffic-management/
3. Istio — Mutual TLS migration (PeerAuthentication, PERMISSIVE → STRICT): https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/
4. Istio — Debugging Envoy with istioctl proxy-config: https://istio.io/latest/docs/ops/diagnostic-tools/proxy-cmd/
