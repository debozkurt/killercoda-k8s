# Done

The autoscaler told you why in its own status: `ScalingActive False`, `FailedGetResourceMetric`, `missing request for cpu`. A CPU-utilization HPA computes `usage ÷ request`, and the target container had no CPU request — no denominator, so the percentage was `<unknown>` and the HPA froze at one replica. metrics-server was healthy the whole time; the gap was on the target. Adding `requests.cpu` gave the HPA its yardstick, and `TARGETS` went from `<unknown>` to a real percentage with `ScalingActive True`.

The lesson that generalizes: **an HPA on CPU (or memory) utilization is only as good as the requests on its target — no request, no percentage, no scaling.** The request you set for the scheduler in M06 does double duty here as the autoscaler's 100% mark, so it has to be honest: too small and the HPA over-scales, too large and it under-scales. When an HPA reads `<unknown>`, check the target's requests before you suspect the metrics pipeline.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Autoscaling.
- Next scenario: **`breakfix-03-rollout-stuck`** — a new release that won't roll out, and the rollback that rescues it.
