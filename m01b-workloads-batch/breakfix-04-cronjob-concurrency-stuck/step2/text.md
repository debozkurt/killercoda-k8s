# Step 2 — Fix it and verify

Two moves: add the guardrail so a hung run can't wedge the schedule again, then clear the run that's wedging it now. Do them in that order, so the next scheduled run uses the fixed template.

## Add the guardrail (and fix the run) — the CronJob is patchable

Unlike a Job, a CronJob is mutable: you edit its `jobTemplate` in place and the change applies to every *future* run. Apply a corrected `cdr-rollup` that (1) gives each run an `activeDeadlineSeconds` cap so a hang self-terminates instead of blocking forever, and (2) restores the aggregation that actually completes:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cdr-rollup
  namespace: cdr-storage
  labels: { app: cdr-rollup, plane: control, tier: lab }
spec:
  schedule: "* * * * *"
  concurrencyPolicy: Forbid
  startingDeadlineSeconds: 60
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    metadata:
      labels: { app: cdr-rollup, plane: control, tier: lab }
    spec:
      activeDeadlineSeconds: 30        # <-- guardrail: a run that overruns is failed, not left to block successors
      backoffLimit: 2
      template:
        metadata:
          labels: { app: cdr-rollup, plane: control, tier: lab }
        spec:
          restartPolicy: OnFailure
          containers:
            - name: rollup
              image: busybox:1.36
              command: ["/bin/sh","-c","echo '[cdr-rollup] aggregating call detail records'; sleep 8; echo '[cdr-rollup] rollup complete'"]
              resources:
                requests: { cpu: 25m, memory: 32Mi }
                limits:   { cpu: 100m, memory: 64Mi }
EOF
```{{exec}}

`concurrencyPolicy: Forbid` stays — it's the right policy. The fix isn't to allow overlap; it's to make sure one run can't run forever. With `activeDeadlineSeconds: 30`, a hung run is terminated and marked `Failed` at 30s, which frees the slot for the next scheduled run. A run that fails loudly is far better than one that wedges the schedule in silence.

## Clear the stuck run

Patching the template does **not** touch the Job that's already running — that one still holds the slot. Delete it:

```bash
kubectl delete job cdr-rollup-29014200 -n cdr-storage
```{{exec}}

(Use the stuck Job's name from your `get jobs` output if it differs.) `ACTIVE` drops to 0, and `Forbid` no longer has anything to forbid — the next minute boundary creates a fresh run from the corrected template.

## Confirm the schedule moves again

```bash
kubectl get cronjob cdr-rollup -n cdr-storage
```{{exec}}

Within a minute, `LAST SCHEDULE` advances and a new `cdr-rollup-<timestamp>` Job appears — one that actually completes:

```bash
kubectl get jobs -n cdr-storage -l app=cdr-rollup
```{{exec}}

A fresh Job at `COMPLETIONS 1/1` and `ACTIVE` back to 0 between runs means the rollup is firing on schedule again, and a future hang will fail fast instead of freezing it.

For self-grading, the full CronJob differential, and why `activeDeadlineSeconds` is the load-bearing guardrail here, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
