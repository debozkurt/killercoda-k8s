# Done

The `FailedScheduling` event pointed straight at it: `didn't match pod anti-affinity rules`. A `required` one-per-node anti-affinity is a hard placement rule, and it needs at least as many schedulable nodes as replicas — three replicas, one schedulable node, two Pods with nowhere legal to go. The rule wasn't broken; the cluster couldn't satisfy it. Softening it to `preferred` let the replicas schedule, at the honest cost of the HA guarantee it was there to provide.

The lesson that generalizes: **`required` affinity and `DoNotSchedule` topology spread are HA and a trap in one.** They enforce distribution and they wedge the moment the schedulable node (or zone) count drops below what the rule needs — a node drain or a zone outage silently turns "highly available" into "won't scale up." Reach for `preferred` / `ScheduleAnyway` unless you genuinely need the hard guarantee *and* have the domains to back it.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Steering and spreading.
- Next scenario: **`breakfix-04-oom-killed`** — the last one flips sides: the Pod schedules fine, then gets killed the moment it runs.
