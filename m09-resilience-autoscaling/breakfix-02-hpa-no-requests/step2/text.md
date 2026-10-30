# Step 2 — Fix it and verify

## Add a CPU request

```bash
kubectl set resources deployment/transcode-scaler -n media --requests=cpu=100m
```{{exec}}

This edits the Pod template and starts a rolling update to a Pod that declares the request. `kubectl edit deployment transcode-scaler -n media` does the same by hand.

## Verify the autoscaler recovers

The HPA reads again on its next loop, and metrics-server needs a sample from the new Pod. Wait 30 seconds, then read:

```bash
kubectl get hpa transcode-scaler -n media
kubectl describe hpa transcode-scaler -n media
```{{exec}}

TARGETS now shows a real percentage, for example 1%/50%. In `Conditions:`, `ScalingActive` is `True`. At idle load the HPA holds the minimum of 1 replica. Above 50% of the request it would scale toward 5.

## Why a request, not a limit

The percentage is measured against the request. The memory limit the container already had was the wrong resource and the wrong field. Two rules to keep:

- **Every container in the Pod needs the request** for a CPU-utilization HPA. A missing request is the most common cause of `<unknown>`. Enforce requests with a `LimitRange` or an admission policy (M20).
- **Size the request honestly.** A request that is too small makes the workload look busy, and the HPA over-scales. One that is too large hides load, and the HPA under-scales.

See [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m09-resilience-autoscaling/ANSWER-KEY.md) for self-grading, then `finish.md`.
