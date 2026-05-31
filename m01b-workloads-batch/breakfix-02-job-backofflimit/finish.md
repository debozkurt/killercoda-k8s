# Done

You diagnosed a Job that couldn't complete because every attempt hit the same broken command, read `backoffLimit`/`restartPolicy` to place it on the retrying-or-given-up spectrum, and fixed it the way Jobs require — delete and recreate, because the pod template is immutable.

Two lessons land here. First: a Job at `0/1` isn't necessarily *stuck* — it may be retrying, or it may have exhausted `backoffLimit` and quit; `.status.conditions` tells you which, and the root-cause work is the same either way. Second: you don't patch-and-roll a Job like a Deployment. It's a disposable record of one execution.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) — including the `OnFailure` vs `Never` difference and why a failed Job won't self-heal on the next GitOps reconcile.
- For the *why*, see [`LESSON.md`](../LESSON.md) § the Job, and the immutability deep dive.
- Next scenario: **`breakfix-03-completions-shortfall`** — the trickiest. A Job that reports `Complete` and is *still* wrong.
