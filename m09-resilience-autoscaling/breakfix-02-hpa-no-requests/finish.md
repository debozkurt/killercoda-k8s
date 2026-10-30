# Done

The autoscaler stated the cause in its own status: `ScalingActive False`, `FailedGetResourceMetric`, and `missing request for cpu in container app of Pod <name>`. A CPU-utilization HPA computes usage divided by the request. The container had no CPU request, so there was no denominator, and the HPA froze at 1 replica. metrics-server was healthy throughout. Adding `requests.cpu` gave the HPA its yardstick.

When an HPA reads `<unknown>`, check the target's requests before you suspect metrics-server. The request you set for the scheduler in M06 is also the autoscaler's 100%, so it must be honest.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Autoscaling.
- Next scenario: **`breakfix-03-rollout-stuck`**. A release that will not roll out, and the rollback that rescues it.
