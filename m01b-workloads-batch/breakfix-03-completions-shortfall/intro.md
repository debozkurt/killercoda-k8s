# M01b — Break/fix 03: Completions Shortfall

> Pre-req: the M01b baseline tour, or comfort with `completions`/`parallelism` and reading Job status.

Finance opens a ticket: **the daily usage export is missing data.** Three of the four daily shards never showed up downstream — but the `usage-export` Job in `analytics` reports `Complete`, exit 0, no errors. Every dashboard says it ran fine.

This is the nastiest kind of batch bug, because nothing looks broken. There's no crash, no retry, no failed pod. The Job did exactly what it was told — it's just that what it was told was *wrong*. This is the batch sibling of M01's "`Running` is not `Ready`": here, **`Complete` is not `correct`.**

Your job is to look past the green status, find the gap between what the Job did and what it was supposed to do, and fix it — which, since this is a Job, means recreating it.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
