# Done

You followed the full life of a Pod on a healthy workload: created through the Deployment → ReplicaSet → Pod chain, kept alive by reconciliation, judged by the three probes, wired into a Service through readiness, and shut down gracefully. That's the shape of "healthy" — internalize it so "broken" stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — each isolates one failure:
  - **`breakfix-01-liveness-restart-loop`** — a healthy app in `CrashLoopBackOff`. Real crash, or a probe killing it?
  - **`breakfix-02-readiness-traffic-blackhole`** — Pods `Running`, Service empty, callers getting nothing.
  - **`breakfix-03-prestop-truncation`** — every rollout drops in-flight work.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
