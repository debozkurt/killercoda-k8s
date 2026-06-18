# Done

You found a CronJob that wasn't suspended and wasn't erroring, yet hadn't produced a fresh run in a while. The tell was `ACTIVE 1` with a single Job stuck `Running` — one hung run holding the only slot `concurrencyPolicy: Forbid` allows, so every successor was skipped. You cleared the stuck run to unblock the schedule, and added `activeDeadlineSeconds` so a future hang fails fast instead of freezing the rollup again.

Two lessons land here. First: `Forbid` is the right policy for most scheduled work, but it turns a single stuck run into a stalled schedule — so a long-running CronJob almost always wants an `activeDeadlineSeconds` guardrail. Second: a CronJob is *patchable* (you edited its `jobTemplate` in place), unlike the immutable Jobs in break/fix 02 and 03 — but the Job that was already stuck still had to be deleted, because a running Job's spec is fixed.

That completes the CronJob differential you started in break/fix 01: suspended, schedule-never-matches, missed-deadline, and now stuck-Active-under-Forbid. A silent scheduled task is almost never a broken controller — it's one of these spec-level causes, read in order.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) — including why this failure escapes alerting and how `activeDeadlineSeconds` converts a silent stall into a loud, catchable failure.
- For the *why*, see [`LESSON.md`](../LESSON.md) § the CronJob.
- That's the last break/fix in M01b. Back to [`LESSON.md`](../LESSON.md) to consolidate, or on to the next module.
