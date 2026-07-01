# Step 1 — Diagnose the OOMKill

This Pod isn't `Pending` — it scheduled. So the scheduler did its job, and the problem is at runtime. That means logs and *last state*, not the `FailedScheduling` event.

## It scheduled, then it didn't stay up

```bash
kubectl get pods -n media -l app=media-buffer -o wide
```{{exec}}

It has a `NODE` and a restart count that's climbing — `CrashLoopBackOff`. Scheduling is done; something is killing the container after it starts.

## Read the last terminated state

```bash
kubectl describe pod -n media -l app=media-buffer | grep -A5 'Last State'
```{{exec}}

```text
Last State:     Terminated
  Reason:       OOMKilled
  Exit Code:    137
```

`OOMKilled`, exit code **137** (128 + signal 9, SIGKILL). The kernel's out-of-memory killer terminated the container for exceeding its **memory limit** — not its request. A too-small limit doesn't stop a Pod scheduling; it stops it *running*.

## Confirm the limit, and the QoS

```bash
kubectl get deploy media-buffer -n media \
  -o jsonpath='{.spec.template.spec.containers[0].resources}'; echo
kubectl get pod -n media -l app=media-buffer -o jsonpath='{.items[0].status.qosClass}'; echo
```{{exec}}

The memory `limit` is `48Mi`, and the QoS class is `Burstable` (request below limit). The workload pre-allocates a ~60Mi buffer at startup — more than 48Mi — so it trips the limit and gets killed every time it launches. The request (`32Mi`) was small enough to schedule; the limit (`48Mi`) is smaller than the container actually needs. On to the fix.
