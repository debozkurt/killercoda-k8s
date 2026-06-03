# Step 4 — CronJob scheduling

`cdr-rollup` is a CronJob: it holds a Job template and a schedule, and on each tick it stamps out a Job. Everything from steps 2–3 applies to those Jobs; the CronJob layer only adds *when* and *whether*.

## Read the schedule and its state

```bash
kubectl get cronjob cdr-rollup -n cdr-storage
```{{exec}}

The columns are the ones you read first when a scheduled task is suspect:

- **`SCHEDULE`** — `* * * * *` (every minute, lab cadence; real cadence would be hourly or nightly like `0 2 * * *`)
- **`SUSPEND`** — `False`. If this were `True`, the CronJob would create nothing and look otherwise fine — the most common "it stopped working" cause.
- **`ACTIVE`** — how many of its Jobs are running right now (0 or 1; a rollup is quick)
- **`LAST SCHEDULE`** — how long ago it last fired. `<none>` means it hasn't fired yet (wait for the next minute boundary).

## See the history it keeps

```bash
kubectl get jobs -n cdr-storage -l app=cdr-rollup
```{{exec}}

One Job per fire, named `cdr-rollup-<timestamp>`. Wait a minute and re-run — a new one appears. The CronJob keeps a bounded history so you can inspect recent runs:

```bash
kubectl describe cronjob cdr-rollup -n cdr-storage
```{{exec}}

`describe` lays the scheduling policy out as named lines near the top:

```text
Concurrency Policy:            Forbid
Successful Job History Limit:  3
Failed Job History Limit:      1
```

It keeps the last 3 successful and 1 failed Job (older ones are garbage-collected), and `Forbid` means if a run is still going when the next is due, the new one is skipped rather than overlapping — right for a rollup, where two runs racing the same data is worse than skipping one.

## Run it on demand

You don't wait for the schedule to test a CronJob — you trigger a Job from its template by hand:

```bash
kubectl create job --from=cronjob/cdr-rollup cdr-rollup-manual -n cdr-storage
kubectl get jobs -n cdr-storage
kubectl logs job/cdr-rollup-manual -n cdr-storage
```{{exec}}

That creates `cdr-rollup-manual` immediately, independent of the schedule. It's how you confirm the Job template works, and how you'd re-run a missed rollup. The logs show `[cdr-rollup] rollup complete`.

## Verify

```bash
kubectl get cronjob cdr-rollup -n cdr-storage
kubectl get jobs -n cdr-storage -l app=cdr-rollup
```{{exec}}

The CronJob's `SUSPEND` column reads `False`, and at least one scheduled `cdr-rollup-<timestamp>` Job is listed. That's a healthy CronJob: not suspended, firing on schedule, keeping history. In `breakfix-01` you'll find one that creates nothing — and learn the short differential for why.

For the *why* behind all of it, read [`LESSON.md`](../LESSON.md). When you're ready to be tested, start **`breakfix-01-cronjob-never-fires`**.
