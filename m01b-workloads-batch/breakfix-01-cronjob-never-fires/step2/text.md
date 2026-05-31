# Step 2 — Fix it and verify

The CronJob is suspended. Un-suspend it. Unlike a Job, a CronJob is *patchable* — `suspend` is one of the fields you can change in place without recreating.

## Un-suspend it

```bash
kubectl patch cronjob cdr-rollup -n cdr-storage \
  -p '{"spec":{"suspend":false}}'
```{{exec}}

Or by hand:

```bash
kubectl edit cronjob cdr-rollup -n cdr-storage
# change  suspend: true  to  suspend: false  (or delete the line; default is false)
```

That's the whole fix. The scheduler now considers `cdr-rollup` again and will create a Job at the next schedule tick (the next minute boundary).

## Don't wait a full cycle — trigger one now

To confirm the template works immediately and to backfill the rollup that should have run, create a Job from the CronJob by hand:

```bash
kubectl create job --from=cronjob/cdr-rollup cdr-rollup-recover -n cdr-storage
kubectl logs job/cdr-rollup-recover -n cdr-storage
```{{exec}}

The logs show `[cdr-rollup] aggregating call detail records` … `rollup complete`. The template was always fine — suspension just kept it from running.

## Confirm the schedule resumes

Wait for the next minute boundary, then check that the scheduler is producing Jobs again:

```bash
kubectl get cronjob cdr-rollup -n cdr-storage
```{{exec}}

`SUSPEND` now reads `False`, and within a minute `LAST SCHEDULE` updates from `<none>` to a fresh timestamp. List the Jobs to see scheduled runs reappearing:

```bash
kubectl get jobs -n cdr-storage -l app=cdr-rollup
```{{exec}}

You'll see `cdr-rollup-recover` (your manual one) and, after the boundary, a scheduled `cdr-rollup-<timestamp>`. The rollup is firing again.

For self-grading, the full CronJob differential, and the production angle (how a suspended CronJob escapes every alert), see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
