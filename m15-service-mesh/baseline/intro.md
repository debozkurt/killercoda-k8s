# M15 — Baseline Tour

M14 shaped traffic with the built-in controls: NetworkPolicy at L3/L4, Ingress at the edge. A **service mesh** adds an L7 dataplane *inside* the pod network. It injects a proxy (Envoy) next to every workload and routes all of that workload's traffic through it — so retries, timeouts, circuit breaking, and mutual TLS become configuration the platform applies, not code each service writes.

This tour runs on the full Polyphone fleet with **Istio** installed and the `media` namespace enrolled in the mesh. The setup labels `media` with `istio-injection=enabled` before its workloads are created, so every media pod comes up with a second container — the Envoy sidecar — and reports `2/2`. On top of that it applies a healthy mesh config for `session-broker`: a **VirtualService** (routing with a timeout and retries), a **DestinationRule** (mTLS mode, a circuit breaker, and named subsets), and a **PeerAuthentication** requiring STRICT mTLS across the namespace. A long-lived `mesh-client` pod is baked in to originate calls from *inside* the mesh (a throwaway `kubectl run` client with a sidecar never terminates cleanly, so we `kubectl exec` into a persistent one instead).

Four short steps:

1. **The sidecar** — what injection did to a pod, and how `istioctl` sees it in the mesh
2. **Traffic management** — the VirtualService and DestinationRule, and the Envoy routes/clusters they compile to
3. **Mesh-managed mTLS** — STRICT enforcement, proven by a plaintext caller getting rejected
4. **Reading Envoy config** — the `istioctl proxy-status` / `proxy-config` toolkit for debugging the dataplane

Nothing to fix here. See what a healthy mesh looks like before the break/fix scenarios snap each layer. Istio plus the fleet take about 3–5 minutes to come up. Click **Start** when ready.
