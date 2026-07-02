# Done

Three Pods, all `Running`, all correctly named — and none of them reachable by name, because the one thing that publishes a StatefulSet Pod's DNS record was missing: the governing **headless Service**. The StatefulSet named it in `serviceName: session-store`, but the controller doesn't create it for you, so `session-store-0.session-store.app-services.svc.cluster.local` returned NXDOMAIN and the members never formed a cluster. One `clusterIP: None` Service selecting the Pods, and every per-Pod name resolved.

Two things worth keeping: **"Pods Running" is not "identity working"** — a StatefulSet has three guarantees and this failure left two of them intact, so nothing looked wrong until you checked the name; and **headless (`clusterIP: None`) is the load-bearing detail** — a normal ClusterIP Service selecting the same Pods still wouldn't publish the per-Pod records.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § The StatefulSet's three guarantees.
- Next scenario: **`breakfix-02-ordered-rollout-stall`** — this time the Pods aren't all there: a StatefulSet stuck with only Pod-0, and the ordered lifecycle that explains why.
