# Done

You toured a healthy mesh. The `media` namespace was labeled for injection, so every workload came up `2/2` — an `app` container plus an injected Envoy `istio-proxy`, with an `istio-init` container programming the iptables redirect that routes the pod's traffic through it. You saw the two traffic-management objects: a **VirtualService** giving `session-broker` a timeout and a retry budget, and a **DestinationRule** defining its subsets, connection pool, and outlier-detection circuit breaker. You confirmed **STRICT mTLS** by watching an in-mesh caller succeed and a plaintext caller from outside the mesh get rejected. And you read the compiled Envoy config with `istioctl proxy-status` and `proxy-config`.

That's the shape of a working mesh. Internalize the request path before you break it:

- a pod is in the mesh only if it has a sidecar (`2/2`, and a line in `proxy-status`)
- L7 rules are applied by the **caller's** Envoy: listener → route → cluster → endpoint
- STRICT mTLS is enforced by the **server's** Envoy: no sidecar or wrong TLS mode → rejected

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order:
  - **`breakfix-01-sidecar-not-injected`** — a workload that isn't in the mesh, and the calls to it that now fail.
  - **`breakfix-02-virtualservice-subset`** — a route that returns `503` with a perfectly healthy backend.
  - **`breakfix-03-mtls-mode-mismatch`** — client and server disagree about mTLS, so nothing gets through.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
