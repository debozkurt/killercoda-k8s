# M24 — Baseline Tour

A stateless service is a herd of interchangeable Pods behind one Service VIP — any replica answers, and losing one costs nothing. Some Polyphone workloads can't work that way. A replicated session cache has to let a peer address *one specific member*; a leader-elected router has to make sure *exactly one* replica makes global decisions at a time. Those workloads need **coordination**: stable identity, direct peer addressing, ordered lifecycle, per-member durable state, and an agreement on who leads.

Kubernetes gives you three primitives for that, and this tour walks all three on the same workload family:

1. **Stable identity & persistent per-Pod storage** — a **StatefulSet** gives each replica a fixed ordinal name (`session-cache-0`, `-1`, `-2`) and its own PVC that follows that identity across restarts
2. **Headless Service & per-Pod DNS** — a Service with `clusterIP: None` publishes a DNS name per Pod, so peers can reach a named member instead of a load-balanced VIP
3. **Ordered, sequential lifecycle** — the default `OrderedReady` policy brings replicas up one at a time, each waiting for the one before it to be Ready
4. **Leader election with Leases** — a `coordination.k8s.io` **Lease** is the lock that records which replica currently leads; the holder renews it to stay leader

This runs on the full Polyphone fleet plus two coordination workloads layered on for the module: **`session-cache`** (a 3-replica StatefulSet — a replicated in-memory cache in the `media` plane) and **`call-coordinator`** (a 2-replica active/standby singleton in `call-routing` that elects a leader). Nothing to fix here — see what healthy coordination looks like before the break/fix scenarios snap each link. The cluster takes 2–3 minutes to come up. Click **Start** when ready.
