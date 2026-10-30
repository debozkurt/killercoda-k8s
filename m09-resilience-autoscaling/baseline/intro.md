# M09 — Baseline Tour

A running service faces three kinds of change. Kubernetes has one control for each:

- **Demand changes.** The **Horizontal Pod Autoscaler** adds and removes replicas to match traffic.
- **Version changes.** A **rolling update** replaces Pods a few at a time, and **rollback** returns to the last good version.
- **Disruption.** A **PodDisruptionBudget** limits how many replicas a voluntary disruption, such as a node drain, takes down at once. **Graceful shutdown** gives each terminating Pod time to finish its work.

The tour runs on the full Polyphone fleet on a 2-node cluster (one tainted control-plane node, one worker). Nothing is broken. You read the healthy controls so a broken one stands out later.

Five steps:

1. **Rolling updates and rollback.** The update strategy, the revision history, and `rollout undo`.
2. **The Horizontal Pod Autoscaler.** A working HPA and the request it divides by.
3. **Push the HPA past its target.** Generate load and watch the replica count rise.
4. **PodDisruptionBudgets.** Allowed disruptions, and the eviction API refusing a second eviction.
5. **Graceful shutdown.** The termination sequence, and a delete that skips the budget.

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
