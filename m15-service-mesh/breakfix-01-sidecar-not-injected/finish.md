# Done

You read a `503` as a mesh-membership problem instead of an application one. The Service had endpoints, DNS resolved, and the app was Ready — but the pod was `1/1` in a `2/2` namespace, absent from `istioctl proxy-status`, carrying `sidecar.istio.io/inject: "false"`. No sidecar meant no terminator for the mTLS every caller was told to use, so the calls `503`'d. Reversing the opt-out rolled a new `2/2` pod, and the calls came back.

The reflex to keep: **a pod is in the mesh only if it has a sidecar — check the container count first.** `2/2` vs `1/1` is the fastest signal that a workload's mesh guarantees (mTLS, retries, timeouts, telemetry) do or don't apply. And note the quieter danger: had the DestinationRule used *automatic* mTLS instead of an explicit `ISTIO_MUTUAL`, this same missing sidecar would have silently downgraded to plaintext — no `503`, just an unencrypted hole. The loud failure here was a gift.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Sidecar injection.
- Next scenario: **`breakfix-02-virtualservice-subset`** — this time the pod is fully in the mesh, and the route still returns `503`.
