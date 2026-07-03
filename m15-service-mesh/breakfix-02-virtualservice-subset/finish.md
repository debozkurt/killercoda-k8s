# Done

You diagnosed a `503` that `kubectl get pods` couldn't see. The pods were `2/2` and healthy, so the break wasn't the workload — it was the route. `istioctl proxy-config routes` showed the request going to the `canary` cluster, and `istioctl proxy-config endpoints` showed that cluster empty: a subset the DestinationRule defined but no pods filled. Pointing the route back at `stable` — a subset with live pods — restored traffic.

The reflex to keep: **a mesh `503` with a healthy backend is a routing problem, and Envoy config is where you see it.** Walk it the way the dataplane does — route → cluster → endpoints — with `istioctl proxy-config`. A VirtualService can name any subset; a subset with zero endpoints is a black hole. This is the classic canary footgun: shift traffic to `version: canary` *before* the canary pods are running, and every request falls into an empty cluster.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Traffic management.
- Last scenario: **`breakfix-03-mtls-mode-mismatch`** — pods `2/2`, subset correct, endpoints present, and still `503` — because the two ends disagree about mTLS.
