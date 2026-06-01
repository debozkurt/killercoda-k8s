# Step 1 — Diagnose the Job that won't finish

The Job is stuck, but the work succeeded. That contradiction is the whole clue: a Job tracks *Pod* success, and a Pod succeeds only when **every** container in it terminates.

## Confirm the stuck Job

```bash
kubectl get job cdr-archive -n cdr-storage
```{{exec}}

`COMPLETIONS 0/1`, no `DURATION` — it's been running indefinitely. Now look at the Pod, and read the `READY` column closely:

```bash
kubectl get pods -n cdr-storage -l app=cdr-archive
```{{exec}}

The Pod is `Running` with `READY 1/2` — **two** containers, only one ready. That's the tell: this is a multi-container Pod, and the two containers are in different states. A Job's Pod can't reach `Succeeded` while a container is still up.

## Read the per-container truth

`get pods` collapses the Pod to one line. Drop to the container level:

```bash
kubectl get pod -n cdr-storage -l app=cdr-archive \
  -o jsonpath='{range .items[0].status.containerStatuses[*]}{.name}{": "}{.state}{"\n"}{end}'
```{{exec}}

```text
archive:     {"terminated":{"reason":"Completed","exitCode":0,...}}
log-shipper: {"running":{...}}
```

There it is. The **archive container finished** — `Terminated`, `Completed`, exit `0`. The work is done. But **log-shipper is still `Running`**, and it always will be. Confirm what it's doing:

```bash
kubectl logs -n cdr-storage -l app=cdr-archive -c log-shipper --tail=3
```{{exec}}

It printed `[log-shipper] streaming logs` and is now sitting on `tail -f` — a process with no end. A Pod is `Succeeded` only when *all* its containers terminate, so this Pod stays `Running` forever, and the Job it belongs to never counts a completion.

## Find the root cause in the spec

```bash
kubectl get job cdr-archive -n cdr-storage \
  -o jsonpath='containers={range .spec.template.spec.containers[*]}{.name}{" "}{end}{"\n"}initContainers={.spec.template.spec.initContainers}{"\n"}'
```{{exec}}

`containers=archive log-shipper`, `initContainers=` (empty). The log-shipper is an **ordinary container** — a long-running helper placed in `spec.containers`. That's the classic sidecar mistake: a helper that must live as long as the app, but modeled as a co-equal container that never exits, so it blocks the Pod (and the Job) from ever completing. The fix is to make it a *native sidecar*. On to step 2.
