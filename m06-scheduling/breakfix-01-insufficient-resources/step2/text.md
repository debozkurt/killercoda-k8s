# Step 2 — Fix it and verify

The request is a `256Mi → 256Gi` unit slip. Correct the memory request (and its matching limit) to a sane value and the scheduler places the Pod on the next pass.

## Right-size the request

```bash
kubectl set resources deployment/stream-analyzer -n analytics \
  --requests=memory=256Mi --limits=memory=512Mi
```{{exec}}

`kubectl set resources` edits just the memory request/limit and leaves CPU alone. This changes the Pod template, so the Deployment rolls a new Pod — with a request that fits.

Or by hand:

```bash
kubectl edit deployment stream-analyzer -n analytics
# under resources: change requests.memory 256Gi -> 256Mi
#                  and    limits.memory   256Gi -> 512Mi
```

## Verify

```bash
kubectl get pods -n analytics -o wide
kubectl get deploy stream-analyzer -n analytics
```{{exec}}

The new Pod goes `Pending → ContainerCreating → Running` within seconds and lands on the worker; the Deployment reports `1/1` available. Confirm the scheduler placed it:

```bash
kubectl describe pod -n analytics -l app=stream-analyzer | grep -A3 Events
```{{exec}}

The event slot now shows `Scheduled … Successfully assigned analytics/stream-analyzer-… to <worker>` instead of `FailedScheduling`. The nodes never changed — the request did. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
