# Done

You read each resilience control while healthy. A Deployment replaced Pods under `maxSurge` and `maxUnavailable`, and `rollout undo` rewound it. An HPA divided usage by the request and scaled out under load. A PodDisruptionBudget let one eviction pass and refused the next. A plain delete skipped that budget.

**Next:**

- Read [`LESSON.md`](../LESSON.md) for the why.
- Work the six break/fix scenarios in order. Each breaks one control you toured:
  - **`breakfix-01-pdb-blocks-drain`**: a budget whose floor equals the replica count, so a drain hangs.
  - **`breakfix-02-hpa-no-requests`**: an HPA stuck at `<unknown>/50%` because the target has no CPU request.
  - **`breakfix-03-rollout-stuck`**: a rollout wedged on a bad image, with the old version still serving.
  - **`breakfix-04-pdb-unready-pods`**: a sane budget that still blocks a drain, because no replica is Ready.
  - **`breakfix-05-sigterm-ignored`**: a Pod that stays `Terminating` for the whole grace period.
  - **`breakfix-06-hpa-quota-capped`**: an HPA that asks for 4 replicas while 2 exist.
- Check each path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
