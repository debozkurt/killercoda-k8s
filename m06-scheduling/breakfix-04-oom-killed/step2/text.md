# Step 2 — Fix it and verify

The container needs about 60Mi, and its limit is 48Mi. Raise the memory limit above the working set.

## Raise the memory limit

```bash
kubectl set resources deployment/media-buffer -n media --limits=memory=128Mi
```{{exec}}

This changes only the memory limit. The request and CPU keep their values. The template change rolls a new Pod.

Or by hand:

```bash
kubectl edit deployment media-buffer -n media
# under resources.limits: memory 48Mi -> 128Mi
```

## Verify

```bash
kubectl get pods -n media -l app=media-buffer -o wide
kubectl get deploy media-buffer -n media
```{{exec}}

The new Pod starts, fills its buffer under the higher limit, and stays `Running`. Its restart count holds at 0, and the Deployment reports `1/1`. Read its state:

```bash
kubectl describe pod -n media -l app=media-buffer
```{{exec}}

`State:` reads `Running`, and there is no `Last State:` block. Now read what the container actually holds (metrics need about a minute):

```bash
kubectl top pod -n media -l app=media-buffer
```{{exec}}

`MEMORY` reads about 60Mi, under the 128Mi limit. You did not touch the request, so placement did not change. You did not change what the application allocates. You gave it a limit that matches its real use.

In production, set the limit from observed peak usage plus headroom. A limit at the steady-state level kills the workload the first time it does something larger than usual.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). Then see `finish.md`.
