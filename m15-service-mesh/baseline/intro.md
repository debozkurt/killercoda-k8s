# M15 — Baseline Tour

M14 shaped traffic with NetworkPolicy and Ingress. A **service mesh** adds an L7 dataplane inside the pod network. It runs a proxy (Envoy) beside each workload and sends the workload's traffic through it. Retries, timeouts, circuit breaking, and mutual TLS then become configuration that the platform applies.

This cluster runs the full Polyphone fleet with **Istio** 1.24 installed. The setup labeled the `media` namespace for sidecar injection before its workloads started, so every media pod runs with an Envoy sidecar. It also applied a healthy mesh configuration for `session-broker`:

- a **VirtualService**: route to the `stable` subset, a timeout, and retries
- a **DestinationRule**: subsets, a circuit breaker, and client mTLS
- a **PeerAuthentication**: `STRICT` mTLS for the whole namespace

Every sidecar writes an access log line per request. A long-lived `mesh-client` pod in `media` sends the test traffic. You run `kubectl exec` into it, because a sidecar keeps a run-to-completion client pod alive after its command ends.

Four steps:

1. **The sidecar**: what injection added to a pod, and how `istioctl` sees it
2. **Traffic management**: the VirtualService and DestinationRule, and the access log line for a request
3. **Mesh mTLS**: `STRICT` mode, and a plaintext caller that the server rejects
4. **Reading Envoy configuration**: `istioctl proxy-status`, `proxy-config`, and `analyze`

Nothing is broken here. Istio and the fleet take about 3 to 5 minutes to start. Click **Start** when ready.
