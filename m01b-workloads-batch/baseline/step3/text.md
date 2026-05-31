# Step 3 — completions and parallelism

A migration runs once. A usage export runs *per shard*. `usage-export` processes 4 daily shards, 2 at a time — that's `completions` and `parallelism`, the two independent knobs that size a Job.

## Read the two knobs

```bash
kubectl get job usage-export -n analytics \
  -o jsonpath='completions={.spec.completions}{"\n"}parallelism={.spec.parallelism}{"\n"}'
```{{exec}}

`completions=4`, `parallelism=2`. They mean different things:

- **`completions: 4`** — the Job needs **4 Pods to succeed** before it's Complete. This is the size of the work: 4 shards.
- **`parallelism: 2`** — at most **2 Pods run at once**. This caps concurrency (and resource use) without changing the total.

So the Job runs 4 Pods total, in two waves of two. Confirm by counting the Pods it created:

```bash
kubectl get pods -n analytics -l app=usage-export
```{{exec}}

Four Pods, all `Completed`. (If you'd watched during setup you'd have seen two `Running` at a time.) The Job's status reflects the same:

```bash
kubectl get job usage-export -n analytics
```{{exec}}

`COMPLETIONS 4/4` — four required, four succeeded. Done.

## The subtle part: Complete means "hit the target," not "did the right amount"

This is the batch sibling of M01's "`Running` ≠ Ready." A Job marks itself `Complete` the instant `succeeded` reaches `completions` — *whatever `completions` was set to*. If someone had set `completions: 1` here, the Job would run **one** shard, report `COMPLETIONS 1/1` and `Complete`, and look perfectly healthy — while 3 of the 4 shards never ran. Nothing errors. Nothing restarts. The status is green and wrong.

```bash
kubectl get job usage-export -n analytics \
  -o jsonpath='{.metadata.name}: succeeded={.status.succeeded}/{.spec.completions}{"\n"}'
```{{exec}}

`succeeded=4/4`. Correctness here lives in whether `4` matches the real number of shards — not in the word `Complete`. That exact failure is `breakfix-03`.

> For statically sharded work where each Pod must own a *specific* partition, there's `completionMode: Indexed` — each Pod gets a stable `JOB_COMPLETION_INDEX` (0…N-1). The default `NonIndexed` mode treats completions as interchangeable, which is fine when Pods pull from a shared queue. See `LESSON.md`.

## Verify

```bash
kubectl get job usage-export -n analytics -o jsonpath='{.status.succeeded}'; echo
```{{exec}}

`4` — all four shards exported. A parallel Job, sized and complete.
