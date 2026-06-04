# Step 1 — Diagnose the silent CronJob

A CronJob that creates nothing has a short differential. Don't guess — read the spec fields that decide *whether* it fires, in order.

## Confirm it's really not firing

```bash
kubectl get cronjob cdr-rollup -n cdr-storage
kubectl get jobs -n cdr-storage -l app=cdr-rollup
```{{exec}}

The CronJob exists, but `LAST SCHEDULE` shows `<none>` (it has never fired) and there are no `cdr-rollup-<timestamp>` Jobs. Compare with the healthy fleet, where a new Job appears every minute. The chain is broken at the very first link: **the CronJob isn't creating Jobs.**

## Work the differential

A CronJob fires nothing for one of a few reasons. Read the columns and the spec:

```bash
kubectl get cronjob cdr-rollup -n cdr-storage
```{{exec}}

The default columns — `SCHEDULE`, `SUSPEND`, `ACTIVE`, `LAST SCHEDULE` — are exactly the differential. Walk them:

- **`SUSPEND True`?** — a suspended CronJob creates nothing and looks otherwise healthy. ← **this one.**
- **Schedule never matches?** — a valid-but-impossible cron like `0 0 31 2 *` (Feb 31) never fires. Here the schedule is `* * * * *`, which matches every minute, so that's not it.
- **A previous run stuck `ACTIVE` with `concurrencyPolicy: Forbid`?** — would block successors. `ACTIVE` is empty here.
- **Runs missed past `startingDeadlineSeconds`?** — `describe` would show "missed schedule" events.

The `SUSPEND` column reads `True`. That's the answer, but confirm it on the resource itself rather than trusting one column — `describe` spells it out and shows the event history in the same view:

```bash
kubectl describe cronjob cdr-rollup -n cdr-storage
```{{exec}}

Near the top, the `Suspend:` line reads:

```text
Suspend:  True
```

The CronJob is suspended — paused. The scheduler skips it entirely, which is exactly why there's no Job, no pod, no error: a suspended CronJob isn't *failing*, it's *switched off*.

## Confirm there's nothing else wrong

A suspended CronJob's Job template can still be perfectly fine — suspension is orthogonal to correctness. In the same `describe` output, scroll to the `Events:` section at the bottom: no warnings — just (likely) no events at all, because a suspended CronJob does nothing worth logging. The template is healthy; it's only the `suspend` flag standing between you and a working rollup. On to the fix.
