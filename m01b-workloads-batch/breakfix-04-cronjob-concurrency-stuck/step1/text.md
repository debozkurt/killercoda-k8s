# Step 1 — Diagnose the stalled schedule

This is the same differential as break/fix 01, but a different branch. Read the columns, in order.

## It's firing nothing — but it isn't suspended

```bash
kubectl get cronjob cdr-rollup -n cdr-storage
```{{exec}}

```text
NAME         SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cdr-rollup   * * * * *     False     1        ...             ...
```

`SUSPEND False` — so this is *not* the suspend case from break/fix 01. But `ACTIVE 1`: there is a run in flight. An every-minute CronJob with one stuck run and nothing newer is the tell. Look at its Jobs:

```bash
kubectl get jobs -n cdr-storage -l app=cdr-rollup
```{{exec}}

One Job — `cdr-rollup-29014200` — `COMPLETIONS 0/1`, and its `AGE` keeps growing. There is only *one*, even though the schedule should have fired several times by now. The chain isn't broken at the CronJob (it created a Job); it's stuck at that Job, which never finishes.

## Why one stuck run stops all the others

```bash
kubectl get cronjob cdr-rollup -n cdr-storage -o yaml | grep -A1 concurrencyPolicy
```{{exec}}

```text
concurrencyPolicy: Forbid
```

`Forbid` means **only one run at a time** — if the previous run is still going when the next is due, the scheduler skips the new one rather than overlapping. That's usually what you want for a rollup (two runs racing the same data is worse than skipping one). But it has a sharp edge: if a run never finishes, *every* successor is skipped, forever. The schedule silently stalls.

## Confirm the run is hung, not failing

```bash
kubectl get pods -n cdr-storage -l app=cdr-rollup
```{{exec}}

The pod is `Running`, `1/1`, no restarts — it isn't crashing. Ask it what it's doing:

```bash
kubectl logs -n cdr-storage -l app=cdr-rollup --tail=5
```{{exec}}

It printed `[cdr-rollup] aggregating call detail records` and then went quiet. The aggregation started and never returned — a hung run (a deadlock, a wedged connection, a lock it never gets). It isn't erroring, so nothing pages; it just sits there holding the one slot `Forbid` allows.

That's the whole picture: **a hung run + `concurrencyPolicy: Forbid` = a frozen schedule.** Two things to fix — clear the stuck run so the schedule moves again, and make sure a future hang can't wedge it the same way. On to step 2.
