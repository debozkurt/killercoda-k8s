# Step 2 — Fix it and verify

The request slipped from 256Mi to 256Gi, and the limit went with it. Correct both, and the scheduler places the next Pod.

## Right-size the request

Both fields sit in the Deployment's Pod template. A change there makes the Deployment roll a new Pod:

```bash
kubectl set resources deployment/stream-analyzer -n analytics \
  --requests=memory=256Mi --limits=memory=512Mi
```{{exec}}

`kubectl set resources` changes only the memory request and limit, and leaves CPU alone.

Or by hand:

```bash
kubectl edit deployment stream-analyzer -n analytics
# under resources: requests.memory 256Gi -> 256Mi
#                  limits.memory   256Gi -> 512Mi
```

## Verify

```bash
kubectl get pods -n analytics -o wide
kubectl get deploy stream-analyzer -n analytics
```{{exec}}

The new Pod moves from `Pending` to `Running` within seconds and lands on the worker. The old `Pending` Pod disappears, and the Deployment reports `1/1`. Read the new Pod's events:

```bash
kubectl describe pod -n analytics -l app=stream-analyzer
```{{exec}}

The last event is `Scheduled`, with `Successfully assigned analytics/stream-analyzer-...` to the worker. The nodes did not change; the request did.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). Then see `finish.md`.
