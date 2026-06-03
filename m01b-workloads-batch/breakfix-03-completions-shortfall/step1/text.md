# Step 1 — Diagnose the green-but-wrong Job

The Job says `Complete`. The data says otherwise. When status and reality disagree, trust the work, not the word — and find where the count came from.

## The status that lies

```bash
kubectl get job usage-export -n analytics
```{{exec}}

`COMPLETIONS 1/1`, `Complete`. By every column this Job is healthy — it hit its target and stopped. That's exactly the problem: a Job marks itself `Complete` the instant `succeeded` reaches `completions`, *whatever `completions` is set to*. So the real question isn't "did it complete" — it's "**was its target the right number?**"

## Compare the target against the real work

The export is supposed to process **4 daily shards**. Read what the Job was actually told to do:

```bash
kubectl describe job usage-export -n analytics
```{{exec}}

Read the sizing and the result together near the top:

```text
Parallelism:    1
Completions:    1
...
Pods Statuses:  0 Active / 1 Succeeded / 0 Failed
```

`Completions: 1` — but the work is 4 shards. There's the gap: the Job was told one success is "done," so it ran **one** pod, succeeded once, and declared victory while shards 2–4 were never touched. `succeeded=1` is true and useless; the number that matters is that `completions` should be `4`.

Confirm only one pod ever ran — no failures hiding, just under-provisioned work:

```bash
kubectl get pods -n analytics -l app=usage-export
```{{exec}}

Exactly one pod, `Completed`, `0` restarts. Nothing failed. Nothing retried. The Job did precisely what its spec said — the spec was just wrong. Read the one pod's log to see it only handled a single shard:

```bash
kubectl logs job/usage-export -n analytics
```{{exec}}

One `[usage-export] processing a usage shard` … `shard complete`. One shard, where there should be four.

## The lesson, stated plainly

A failing Job is loud — it errors, retries, pages someone. A Job with the wrong `completions` is **silent**: green status, clean logs, zero alerts, three-quarters of the data missing. This is the batch form of "`Running` ≠ `Ready`" from M01 — `Complete` ≠ `correct`. The fix is to size `completions` to the real work. Because it's a Job, that means recreating it.
