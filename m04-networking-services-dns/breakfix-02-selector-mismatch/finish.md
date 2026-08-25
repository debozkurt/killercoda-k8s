# Done

You found a black hole: a Service with a ClusterIP, healthy Pods, no errors anywhere — and an empty EndpointSlice routing traffic to nothing. The `get svc` headline was green; `get endpointslice` told the truth. The cause was a selector that matched no Pod's labels, and the fix touched only the Service — the Pods were never the problem.

That instinct — **when connectivity breaks but Pods look healthy, read the endpoints before anything else** — is the most important reflex in the module, and the second leaf of the differential. It's the same "the headline status lies" pattern as `Running` ≠ `Ready` (M01) and `Complete` ≠ correct (M01b), now at the Service layer.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § A Service is a stable identity.
- Next scenario: **`breakfix-03-port-mismatch`** — this time the endpoints are populated, and the connection is *still* refused.
