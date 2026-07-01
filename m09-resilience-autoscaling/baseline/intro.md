# M09 — Baseline Tour

A service doesn't stay available by accident. It stays available because Kubernetes has machinery for surviving *change* — the three kinds that constantly happen to a running fleet:

- **Demand changes** — traffic rises and falls. The **Horizontal Pod Autoscaler** adds and removes replicas to match.
- **Version changes** — you ship a new release. A **rolling update** replaces Pods a few at a time, and **rollback** rewinds to the last good version when a release goes bad.
- **Disruption** — nodes get drained for patching, or die outright. A **PodDisruptionBudget** caps how many replicas a *voluntary* disruption may take down at once, and **graceful shutdown** gives a terminating Pod time to finish in-flight work.

This tour runs on the full Polyphone fleet on a 2-node cluster (one tainted control-plane, one worker). Nothing is broken — you're learning to *read* the healthy machinery before the break/fix scenarios break one piece each.

Four short steps:

1. **Rolling updates and rollback** — a Deployment's update strategy, its revision history, and how `rollout undo` rewinds it
2. **The Horizontal Pod Autoscaler** — a working HPA reading CPU utilization off metrics-server
3. **PodDisruptionBudgets** — the budget that lets a drain proceed safely, and the "allowed disruptions" number that drives it
4. **Graceful shutdown** — the termination lifecycle a Pod goes through when a rollout or a drain removes it

See what healthy resilience looks like, so a broken autoscaler or a wedged rollout stands out later. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
