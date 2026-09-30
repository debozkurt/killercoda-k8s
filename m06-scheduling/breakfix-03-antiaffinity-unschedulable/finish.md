# Done

The `FailedScheduling` event named the filter: `didn't match pod anti-affinity rules`. A required one-per-node rule needs at least as many schedulable nodes as replicas. Three replicas and one schedulable node left two Pods with nowhere legal to go. Softening the rule to `preferred` was the right fix, but the rollout stalled: the old Pod's hard rule repelled its own replacements with `didn't satisfy existing pods anti-affinity rules`. Scaling to 0 and back cleared it.

The lesson that generalizes: **a hard placement rule is an availability guarantee and a trap.** `required` anti-affinity and `DoNotSchedule` spread leave replicas `Pending` when the domains run out, and required anti-affinity also blocks a Deployment's own new Pods on a full cluster.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Steering and spreading, and the deep dive on hard rules during rollouts.
- Next scenario: **`breakfix-04-oom-killed`**. This one flips sides: the Pod schedules, then dies at runtime.
