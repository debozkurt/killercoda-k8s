# Step 1 — Diagnose the dead autoscaler

An HPA that does not scale states why in its own status. Read it before you touch anything.

## See the unknown target

```bash
kubectl get hpa -n media
kubectl top pods -n media
```{{exec}}

`transcode-scaler` shows TARGETS `<unknown>` over 50% and REPLICAS 1. Unknown means the HPA has no number at all. It does not mean 0% load. `kubectl top` returns CPU for the Pod, so metrics-server works.

## Read the autoscaler's status

```bash
kubectl describe hpa transcode-scaler -n media
```{{exec}}

Read `Conditions:`. `AbleToScale` is `True`. `ScalingActive` is `False` with reason `FailedGetResourceMetric`. The message ends:

```text
failed to get cpu utilization: missing request for cpu in container app of Pod transcode-scaler-...
```

The HPA computes utilization as usage divided by the request. This container has no CPU request, so the division has no denominator.

## Confirm on the target

```bash
kubectl describe deployment transcode-scaler -n media
```{{exec}}

In the Pod template, find `Limits:`. It lists memory 128Mi and no CPU. There is no `Requests:` block. Compare the workload behind the baseline's working HPA:

```bash
kubectl describe deployment sip-router -n signaling
```{{exec}}

`sip-router` has a `Requests:` block with cpu 25m. That is the denominator. Add one to `transcode-scaler` next.
