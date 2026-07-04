# Done

You told a NodePort-layer failure apart from a workload failure. The Pod was `Running` and `Ready`, the EndpointSlice was populated, `get svc` was normal — and traffic still died on one node, because `externalTrafficPolicy: Local` drops on any node without a local endpoint. Reproducing the split per node IP made the pattern obvious; switching to `Cluster` (or, in production, guaranteeing an endpoint per node) restored reachability.

That instinct — **when reachability depends on which node you hit, read `externalTrafficPolicy` and check where the endpoints are** — is the last host-networking trap in this module, and the one most likely to page you during a rollout that drains a node.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § External traffic and `externalTrafficPolicy`.
- You've finished M22's three scenarios. Reread the `LESSON.md` Recap to consolidate the four escape hatches and their failure signatures.
