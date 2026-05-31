# Step 1 — The batch owner chains

In M01 the chain was Deployment → ReplicaSet → Pod. Batch has two chains, and seeing them is the foundation for diagnosing every batch failure: when something misbehaves, you ask *which link broke*.

## A Job owns its Pods directly

```bash
kubectl get job,pods -n provisioning -l app=schema-migrate
```{{exec}}

One Job (`schema-migrate`) and one Pod (`schema-migrate-<id>`). A Job is simpler than a Deployment — no ReplicaSet in between. The Job creates Pods directly:

```text
Job  ── creates ──▶  Pod        (run to completion, exit 0)
```

The Pod shows `STATUS Completed` and the Job shows `COMPLETIONS 1/1` — it ran, succeeded, and stopped. Confirm the ownership is recorded, not just implied by the name:

```bash
kubectl get pod -n provisioning -l app=schema-migrate \
  -o jsonpath='{.items[0].metadata.ownerReferences[0].kind}/{.items[0].metadata.ownerReferences[0].name}'; echo
```{{exec}}

That prints `Job/schema-migrate` — the Pod knows its owner. Same M01 instinct: a failure creating the Pod lands as an event on the Job, not on a Pod that doesn't exist.

## A CronJob owns Jobs, which own Pods

The CronJob adds a link on top. Look at all three levels for `cdr-rollup`:

```bash
kubectl get cronjob,job,pods -n cdr-storage -l app=cdr-rollup
```{{exec}}

```text
CronJob  ── creates on schedule ──▶  Job  ── creates ──▶  Pod
```

You'll see one CronJob (`cdr-rollup`), one or more Jobs named `cdr-rollup-<timestamp>` (one per fire), and their Pods. The timestamp suffix is the scheduled time — that's how you tell which run is which. Trace the chain explicitly:

```bash
JOB=$(kubectl get jobs -n cdr-storage -l app=cdr-rollup -o jsonpath='{.items[0].metadata.name}')
kubectl get job $JOB -n cdr-storage \
  -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}'; echo
```{{exec}}

That prints `CronJob/cdr-rollup` — the Job knows the CronJob created it. (If no Job exists yet, the CronJob hasn't hit its first minute boundary — wait and re-run.)

## Why the chains matter

A scheduled task that misbehaves has three places it can break, one per link:

- **CronJob didn't create a Job** → look at the CronJob (`SUSPEND`, `LAST SCHEDULE`, schedule, events)
- **Job didn't create succeeding Pods** → look at the Job (`COMPLETIONS`, `backoffLimit`, events)
- **Pods ran but failed** → look at the Pod (logs, exit code)

The three breakfix scenarios each live at a different link. Internalize the chain now.

## Verify

```bash
kubectl get jobs -A
```{{exec}}

You should see `schema-migrate` (`provisioning`) and `usage-export` (`analytics`) as Complete, plus one or more `cdr-rollup-<timestamp>` Jobs in `cdr-storage`. That's the batch fleet: two standalone Jobs and a CronJob steadily producing more.
