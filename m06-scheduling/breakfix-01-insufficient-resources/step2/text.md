# Step 2 — Fix it and verify

The request slipped from 256Mi to 256Gi, and the limit went with it. Correct both, and the scheduler places the next Pod.

## Restore the intended resources

Set the complete intended resource contract. A change to the Pod template starts a rollout automatically:

```bash
kubectl set resources deployment/stream-analyzer -n analytics \
  --requests=cpu=10m,memory=256Mi \
  --limits=cpu=200m,memory=512Mi
```{{exec}}

The CPU request matters because the baseline deliberately packs one worker. Changing only memory can expose a second failure, `Insufficient cpu`, if the Deployment still carries the older `100m` request.

Or by hand:

```bash
kubectl edit deployment stream-analyzer -n analytics
# under resources: requests.memory 256Gi -> 256Mi
#                  limits.memory   256Gi -> 512Mi
#                  requests.cpu    100m  -> 10m  (older lab sessions)
```

## Verify

```bash
kubectl rollout status deployment/stream-analyzer -n analytics --timeout=120s
kubectl get pods -n analytics -o wide
kubectl get deploy stream-analyzer -n analytics
```{{exec}}

The new Pod moves from `Pending` to `Running` and lands on the worker. After it becomes available, the Deployment removes the old Pending ReplicaSet Pod and reports `1/1`. Read the running Pod's events:

```bash
kubectl describe pod -n analytics -l app=stream-analyzer
```{{exec}}

The events include `Scheduled`, with `Successfully assigned analytics/stream-analyzer-...` to the worker. The nodes did not change; the resource contract did.

Do not run `rollout restart` as a repair step. `kubectl set resources` already starts a rollout, and restarting without changing the requests only creates another unschedulable Pod.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). Then see `finish.md`.
