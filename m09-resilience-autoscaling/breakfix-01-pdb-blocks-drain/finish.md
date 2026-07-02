# Done

The workload was healthy the whole time — the block was the budget guarding it. `kubectl get pdb` showed `ALLOWED DISRUPTIONS 0`, and the eviction API refused every attempt with `Cannot evict pod as it would violate the pod's disruption budget`. The math was `currentHealthy(2) − desiredHealthy(2) = 0`: a `minAvailable` equal to the replica count is unsatisfiable for any disruption. Lowering it to `1` gave the budget one disruption's worth of headroom, and the drain could proceed.

The lesson that generalizes: **a PDB paces voluntary disruption, it doesn't prevent it — and a budget with no headroom blocks maintenance instead of protecting the service.** `minAvailable` at (or above) the replica count, or `maxUnavailable: 0`, means `ALLOWED DISRUPTIONS 0`, and every drain, node upgrade, or autoscaler scale-down hangs on it. Prefer `maxUnavailable` when an HPA moves the replica count, and always leave room for at least one Pod to go at a time.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Disruption budgets and graceful shutdown.
- Next scenario: **`breakfix-02-hpa-no-requests`** — an autoscaler that can't read its own metric.
