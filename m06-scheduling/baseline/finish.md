# Done

You read the fleet's placement top to bottom: the two nodes and the control-plane taint that keeps ordinary Pods on the worker, the requests/limits/QoS contract each Pod carries (and the `kubectl top` vs. `requests` distinction), the nodeAffinity and tolerations the fleet already uses to steer placement, and the scheduler's `Scheduled` event plus the Allocatable headroom that decides what fits next. That's the shape of "healthy" — internalize it so each broken placement stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the four break/fix scenarios, in order — the first three walk the `Pending` differential (one `FailedScheduling` signature each), the fourth flips to the runtime side:
  - **`breakfix-01-insufficient-resources`** — `Pending`, `Insufficient memory`: a request that fits no node.
  - **`breakfix-02-untolerated-taint`** — `Pending`, `untolerated taint`: a node that pushes the Pod away.
  - **`breakfix-03-antiaffinity-unschedulable`** — replicas `Pending`: a hard spread rule with nowhere to spread.
  - **`breakfix-04-oom-killed`** — schedules fine, then `OOMKilled`: a limit below the working set.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
