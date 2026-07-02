# Done

You read Polyphone's resilience machinery in its healthy state: a Deployment's rolling-update strategy and revision history (and how `rollout undo` rewinds it), a working HPA computing CPU utilization as a percentage of the container's request, a PodDisruptionBudget with one allowed disruption's worth of headroom for a safe drain, and the graceful-termination lifecycle every Pod goes through when a rollout or drain removes it. That's the shape of "healthy" — internalize it so each broken piece stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — each breaks one piece you just toured:
  - **`breakfix-01-pdb-blocks-drain`** — a PodDisruptionBudget with `minAvailable` set so high that `ALLOWED DISRUPTIONS` is `0`, and a node drain blocks forever.
  - **`breakfix-02-hpa-no-requests`** — an HPA stuck at `<unknown>/50%`: the target has no CPU request, so there's no percentage to compute.
  - **`breakfix-03-rollout-stuck`** — a rolling update wedged on a bad image, the old version still serving, waiting for a rollback.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
