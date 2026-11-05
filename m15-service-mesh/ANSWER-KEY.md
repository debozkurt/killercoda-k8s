# M15 — Service Mesh — Answer Key

> Self-grading reference. Work each scenario first, then compare your diagnostic path with the canonical one. Instructors can use the same sections as a teaching script.
>
> Environment: Killercoda `kubernetes-kubeadm-2nodes`, the Polyphone fleet, and Istio 1.24 (minimal profile, access logging on). The `media` namespace has `istio-injection=enabled`. `session-broker` has a VirtualService (route to `stable`, `timeout: 3s`, 2 retries), a DestinationRule (subsets `stable` and `canary`, connection pool, outlier detection, `tls: ISTIO_MUTUAL`), and a namespace-wide `STRICT` PeerAuthentication. Its Service port is named `http`. A long-lived `mesh-client` pod in `media` sends the test traffic.

## Lesson summary

Five scenarios break five links of the mesh request path. Four reach the caller as `503`; one reaches it as a connection reset. The fastest discriminator is the caller sidecar's access log line, whose response flag names the link<sup><a href="https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage">[1]</a></sup>:

| Scenario | Caller sees | Caller access log | Server sidecar log | Pods |
|---|---|---|---|---|
| `breakfix-01-sidecar-not-injected` | `503`, `TLS_error` | `URX,UF` | none (no sidecar) | server `1/1` |
| `breakfix-02-virtualservice-subset` | `503 no healthy upstream` | `UH`, cluster `\|canary\|` | nothing | all `2/2` |
| `breakfix-03-mtls-mode-mismatch` | `503 ... connection termination` | `URX,UC` | `NR filter_chain_not_found` ×3 | all `2/2` |
| `breakfix-04-injection-not-restarted` | reset, `curl` exit 56 | none (no sidecar) | `NR filter_chain_not_found` | caller `1/1` |
| `breakfix-05-fault-injection-left-on` | about 50% `503 fault filter abort` | `FI` | only `200` lines | all `2/2` |

The through-line: **a mesh failure with healthy pods is a dataplane configuration problem. Read the caller's access log first, then confirm with `istioctl`.**

## Baseline tour reference

No broken state. Expected results per step:

- **Step 1 (the sidecar):** `media` has `istio-injection=enabled`. `media` pods are `2/2`; `signaling` pods are `1/1`. `kubectl describe pod -l app=session-broker` lists `istio-init` under `Init Containers:` and `app` plus `istio-proxy` under `Containers:`. `istioctl proxy-status` shows each sidecar with `SYNCED (Ns)` in `CDS`, `LDS`, `EDS`, `RDS` and `IGNORED` in `ECDS`.
- **Step 2 (traffic management):** `describe virtualservice` shows `Subset: stable`, `Timeout: 3s`, `Attempts: 2`. The DestinationRule YAML shows `stable` (`app: session-broker`) and `canary` (`version: canary`). The call returns `200`, and the caller's log line names `outbound|80|stable|session-broker.media.svc.cluster.local`. `proxy-config routes --name 80` shows `session-broker.media` in the `VIRTUAL SERVICE` column.
- **Step 3 (mTLS):** `get peerauthentication` shows `MODE STRICT`. The meshed call returns `200`. `proxy-config secret` shows a `default` certificate that expires about 24 hours after issue. The plaintext pod in `signaling` gets `curl: (56) Recv failure: Connection reset by peer` and `HTTP 000`; the server sidecar logs `NR filter_chain_not_found`.
- **Step 4 (Envoy configuration):** three `session-broker` clusters (subset `-`, `canary`, `stable`); endpoint rows for `|stable|` and the subset-less cluster, none for `|canary|`; a `0.0.0.0` port-80 listener with `Route: 80`; `istioctl analyze -n media` reports no issues.

---

## Break/fix 01 — Sidecar not injected

**Symptom:** callers of `session-broker` get `503` with a body that ends in a `TLS_error` (`WRONG_VERSION_NUMBER`). The pod is `Running` and `Ready`, and the Service has an endpoint.

**Root cause:** the Deployment's pod template carries the label `sidecar.istio.io/inject: "false"`. It overrides the namespace's `istio-injection=enabled`, so the pod starts `1/1` with no Envoy<sup><a href="https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/">[2]</a></sup>. The DestinationRule still tells every caller to send `ISTIO_MUTUAL` mTLS. Plain nginx receives a TLS handshake and answers in plaintext, so the caller's Envoy reports an upstream connection failure.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce with the body: 503, TLS_error
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -w "\nHTTP %{http_code}\n" --max-time 5 http://session-broker.media/

# 2. Caller log: 503 URX,UF ... WRONG_VERSION_NUMBER, upstream = the pod IP on port 80
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=1

# 3. The server answered in plaintext. Does it have a sidecar?
kubectl get pods -n media                    # session-broker 1/1
istioctl proxy-status                        # no session-broker row

# 4. Why the injector skipped it
kubectl get pods -n media -l app=session-broker --show-labels
#    ... sidecar.istio.io/inject=false ...
```

**Fix:** remove the opt-out label from the pod template. A merge patch with `null` deletes the key, and the template change rolls the pod:

```bash
kubectl patch deployment session-broker -n media \
  -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject":null}}}}}'
kubectl rollout status deployment session-broker -n media
```

**Verify:** `kubectl get pods -n media -l app=session-broker` shows `2/2`; `istioctl proxy-status` has a `session-broker` row; the call returns `200`; `kubectl get peerauthentication -n media` still shows `STRICT`.

**What this scenario tests:** reading `UF` with a `TLS_error` as "the server did not speak TLS", and checking mesh membership before the application. Self-grading questions:

- Did the access log send you to the server's sidecar before you looked at nginx?
- Did you check the pod's own labels after you saw that the namespace label was correct?
- Did you fix membership and leave `STRICT` and `ISTIO_MUTUAL` unchanged?

**Expected time:** 4–8 min with the access-log reflex; 12–20 min the first time.

**Production thinking:** an opt-out label usually comes from a chart default or a copy of a job template. Under automatic mTLS the same missing sidecar would not fail: callers would switch to plaintext and the hop would run unencrypted. Alert on structure, not on errors: every pod in an enrolled namespace must run `istio-proxy`, and a policy engine (M20) can reject `sidecar.istio.io/inject: "false"` outside an allowlist.

---

## Break/fix 02 — VirtualService subset

**Symptom:** every call returns `503` with the body `no healthy upstream`. Every pod is `2/2`, `istioctl proxy-status` shows `SYNCED`, and the Service has an endpoint.

**Root cause:** the VirtualService routes to `subset: canary`. The DestinationRule defines `canary` as `version: canary`, and no pod carries that label. `istiod` builds the cluster `outbound|80|canary|session-broker.media.svc.cluster.local` with zero endpoints, and Envoy answers each request with `503` and the flag `UH`<sup><a href="https://istio.io/latest/docs/concepts/traffic-management/">[3]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce: 503, "no healthy upstream"
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -w "\nHTTP %{http_code}\n" --max-time 5 http://session-broker.media/

# 2. Caller log: 503 UH no_healthy_upstream ... outbound|80|canary|session-broker...
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=1

# 3. Route and subset definition
kubectl describe virtualservice session-broker -n media           # Subset: canary
kubectl get destinationrule session-broker -n media -o yaml       # canary -> version: canary
kubectl get pods -n media -l version=canary                       # No resources found

# 4. Envoy holds an empty cluster
istioctl proxy-config endpoints deployment/mesh-client -n media \
  --cluster "outbound|80|canary|session-broker.media.svc.cluster.local"   # header only
```

**Fix:** no canary build exists, so route to `stable`:

```bash
kubectl patch virtualservice session-broker -n media --type=json \
  -p '[{"op":"replace","path":"/spec/http/0/route/0/destination/subset","value":"stable"}]'
```

**Verify:** the call returns `200`, and the next caller log line names `outbound|80|stable|...` with no flag.

**What this scenario tests:** following the request through route → cluster → endpoints when the workload is healthy. Self-grading questions:

- Did you get the subset name from the cluster in the log line, or did you guess it from the objects?
- Can you explain why `istioctl analyze` reports nothing here, although it reports a route to an undefined subset?
- Did you confirm the empty cluster in `proxy-config endpoints` before you changed the route?

**Expected time:** 4–8 min with the access-log reflex; 10–18 min the first time.

**Production thinking:** this is the canary failure: traffic moves to a subset before its pods are `Ready`. Gate each weight change on the subset's ready endpoint count, and roll back the route automatically when `UH` responses appear. A route that sends a fraction of traffic to the empty subset produces the same fraction of `503`s.

---

## Break/fix 03 — mTLS mode mismatch

**Symptom:** every call returns `503` with the reason `connection termination`. Every pod is `2/2`, the route targets `stable`, and `stable` has an endpoint.

**Root cause:** the DestinationRule sets `tls.mode: DISABLE`, so every caller sidecar sends plaintext. The `default` PeerAuthentication is `STRICT`, so the server sidecar has no filter chain for plaintext and closes the connection<sup><a href="https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/">[4]</a></sup>. The caller's Envoy reports `UC` after the retries (`URX`).

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce: 503, "... reset reason: connection termination"
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -w "\nHTTP %{http_code}\n" --max-time 5 http://session-broker.media/

# 2. Caller log: 503 URX,UC, cluster |stable|, upstream = a pod IP (route and endpoint are fine)
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=1

# 3. Server log: one NR filter_chain_not_found per attempt (3)
kubectl logs -n media deploy/session-broker -c istio-proxy --tail=3

# 4. Both sides of the contract
kubectl get peerauthentication -n media                           # MODE STRICT
kubectl describe destinationrule session-broker -n media          # Tls: Mode: DISABLE
```

**Fix:** set the client side to mTLS. Removing the `tls` block also works, because automatic mTLS then applies:

```bash
kubectl patch destinationrule session-broker -n media --type=json \
  -p '[{"op":"replace","path":"/spec/trafficPolicy/tls/mode","value":"ISTIO_MUTUAL"}]'
```

**Verify:** the call returns `200`, and `kubectl get peerauthentication -n media` still shows `STRICT`.

<details>
<summary>📖 Going deeper: why the server logs NR, not a TLS error<sup><a href="https://istio.io/latest/docs/ops/diagnostic-tools/proxy-cmd/">[5]</a></sup></summary>

The sidecar receives all inbound traffic on one listener, port 15006, which holds filter chains that match on the connection's transport protocol and original port. Under `STRICT`, the chain for port 80 matches only TLS. A plaintext connection matches no chain, so Envoy logs `NR` with the detail `filter_chain_not_found` and closes the socket before any HTTP parsing. That is why the server-side line has no method, path, or status. `istioctl proxy-config listeners deployment/session-broker -n media --port 15006` shows the chain as `Trans: tls; Addr: *:80`.

</details>

**What this scenario tests:** reading `UC` plus a server-side `filter_chain_not_found` as a transport disagreement, and repairing it in the safe direction. Self-grading questions:

- Did the healthy upstream address in the caller log rule out routing and endpoints for you?
- Did you read the PeerAuthentication and the DestinationRule together?
- Did you change the client, not the server?

**Expected time:** 5–10 min with the access-log reflex; 12–20 min the first time.

**Production thinking:** an explicit `tls` block in a DestinationRule overrides automatic mTLS for every caller. Most teams need none. Treat `tls.mode: DISABLE` on a mesh host as a review flag. If a plaintext path is truly required during a migration, use a `PERMISSIVE` PeerAuthentication scoped by `selector` to one workload, with an expiry date, instead of a namespace-wide change.

---

## Break/fix 04 — Injection not restarted

**Symptom:** `session-dialer` in `signaling` gets `curl: (56) Recv failure: Connection reset by peer` (`HTTP 000`) from `session-broker`. Callers in `media` get `200`. The `signaling` namespace was enrolled in the mesh the day before.

**Root cause:** the `signaling` namespace got `istio-injection=enabled` after its pods started. Injection happens only when a pod is created, so `session-dialer` still runs `1/1` without a sidecar<sup><a href="https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/">[2]</a></sup>. It sends plaintext to the `STRICT` server, which closes the connection. With no Envoy on the caller side, nothing turns the close into an HTTP `503`.

**Diagnostic commands (the canonical path):**

```bash
# 1. Reproduce: a reset, not a 503
kubectl exec -n signaling deploy/session-dialer -- \
  curl -sS -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/

# 2. A meshed caller works
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/

# 3. Server log: NR filter_chain_not_found (plaintext into STRICT)
kubectl logs -n media deploy/session-broker -c istio-proxy --tail=1

# 4. Caller membership: label present, pods 1/1
kubectl get pods -n signaling
kubectl get namespace signaling --show-labels
```

**Fix:** recreate the caller so that the webhook admits it with a sidecar:

```bash
kubectl rollout restart deployment session-dialer -n signaling
kubectl rollout status deployment session-dialer -n signaling
```

**Verify:** `kubectl get pods -n signaling -l app=session-dialer` shows `2/2`, the call returns `200`, and `media` is still `STRICT`.

**What this scenario tests:** telling a caller-side failure from a server-side one by the shape of the error. Self-grading questions:

- Did you notice that the failure had no HTTP status, and conclude that no caller sidecar answered?
- After you saw the namespace label, did you ask when the pods were created?
- Did you leave `STRICT` in place?

**Expected time:** 4–8 min once a reset reads as "no caller Envoy"; 10–20 min the first time.

**Production thinking:** enrollment is two steps: label the namespace, then restart every workload in it. Restart in dependency order, a few Deployments at a time, and watch error rates between batches. Keep the destination `PERMISSIVE` until telemetry shows that every caller sends mTLS, then switch to `STRICT`. A check that lists `1/1` pods in labeled namespaces catches an enrollment that stopped halfway.

---

## Break/fix 05 — Fault injection left on

**Symptom:** about half the calls to `session-broker` return `503` with the body `fault filter abort`. Pods are `2/2`, nothing restarted, and the server team sees no errors in their logs.

**Root cause:** the VirtualService route still has a `fault.abort` block (`httpStatus: 503`, `percentage: 50`) from a resilience test. The caller's Envoy aborts those requests itself before they leave the pod, with the flag `FI`<sup><a href="https://istio.io/latest/docs/tasks/traffic-management/fault-injection/">[6]</a></sup>. Retries do not repeat an injected abort, and the server never sees the aborted requests.

**Diagnostic commands (the canonical path):**

```bash
# 1. Measure: a mix of 200 and 503
kubectl exec -n media deploy/mesh-client -c curl -- sh -c \
  'for i in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null -w "%{http_code} " --max-time 5 http://session-broker.media/; done; echo'

# 2. Caller log: 503 FI fault_filter_abort, upstream host "-"
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=10

# 3. Server log: only 200 request lines
kubectl logs -n media deploy/session-broker -c istio-proxy --tail=10

# 4. The fault in the route
kubectl describe virtualservice session-broker -n media          # Fault: Abort: Http Status 503, Percentage 50
```

**Fix:** remove the `fault` block and keep the timeout and retries:

```bash
kubectl patch virtualservice session-broker -n media --type=json \
  -p '[{"op":"remove","path":"/spec/http/0/fault"}]'
```

**Verify:** ten calls in a row return `200`.

**What this scenario tests:** locating which proxy produced an error when the server logs are clean. Self-grading questions:

- Did the `-` upstream host in the caller log tell you that the request never left the pod?
- Did you compare the caller's error count with the server's request count?
- Did you remove only the fault, and keep the rest of the route?

**Expected time:** 3–6 min with the access-log reflex; 10–15 min the first time.

**Production thinking:** apply test faults with a header `match` (for example `x-chaos: true`) so that only test traffic is affected, and remove them in the same runbook that adds them. Error-rate alerts measured at the server miss caller-side aborts. Measure success rate from the caller's sidecar metrics too.

---

## References

1. Envoy — Access logging (format, response flags): https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage
2. Istio — Installing the sidecar (automatic injection, injection labels): https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/
3. Istio — Traffic management (VirtualService, subsets): https://istio.io/latest/docs/concepts/traffic-management/
4. Istio — Mutual TLS migration: https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/
5. Istio — Debugging Envoy and istiod: https://istio.io/latest/docs/ops/diagnostic-tools/proxy-cmd/
6. Istio — Fault injection: https://istio.io/latest/docs/tasks/traffic-management/fault-injection/
