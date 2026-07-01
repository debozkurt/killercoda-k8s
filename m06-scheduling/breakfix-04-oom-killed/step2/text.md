# Step 2 — Fix it and verify

The container needs ~60Mi and its limit is 48Mi. Raise the memory limit above the working set and the OOM kills stop.

## Raise the memory limit

```bash
kubectl set resources deployment/media-buffer -n media --limits=memory=128Mi
```{{exec}}

`set resources` changes only the memory limit (request and CPU stay as they were), which rolls a fresh Pod with a ceiling the buffer fits under.

Or by hand:

```bash
kubectl edit deployment media-buffer -n media
# under resources.limits: change memory 48Mi -> 128Mi
```

## Verify

```bash
kubectl get pods -n media -l app=media-buffer -o wide
kubectl get deploy media-buffer -n media
```{{exec}}

The new Pod starts, allocates its buffer under the higher limit, and stays `Running` — restart count holds at 0 and the Deployment reports `1/1`. Confirm it's no longer being killed:

```bash
kubectl describe pod -n media -l app=media-buffer | grep -A3 'State:'
```{{exec}}

`State: Running`, with no `OOMKilled` in the last state. Note what you did *not* do: you didn't touch the request (so scheduling is unchanged), and you didn't change what the app allocates — you gave it a realistic ceiling.

A sharper fix in production is to set the limit from *observed* usage (`kubectl top pod`), not a guess, and to leave headroom above the peak — a limit pinned to steady-state usage OOMs the first time a workload does something bigger than steady state. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
