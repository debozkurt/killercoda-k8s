# Done

The HPA was healthy the whole time. It read a real percentage and asked for 4 replicas. A ResourceQuota capped the namespace at 2 Pods, so admission refused the other two and the ReplicaSet logged `FailedCreate`. The Deployment stayed at READY 2/4 with no `Pending` Pod to find. Raising the cap and nudging the ReplicaSet delivered the Pods.

A desired count is not a running count. When `get hpa` is fine and `get deploy` is short, walk down: ReplicaSet events, admission (quota), the scheduler (`Pending`), then the node.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Autoscaling.
- That is the last break/fix in M09. Revisit the baseline or `LESSON.md` to consolidate, then on to M10.
