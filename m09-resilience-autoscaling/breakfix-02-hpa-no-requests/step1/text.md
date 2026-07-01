# Step 1 — Diagnose the dead autoscaler

An HPA that won't scale tells you why in its own status. Read it before touching anything else.

## See the unknown target

```bash
kubectl get hpa -n media
```{{exec}}

`transcode-scaler` shows `TARGETS <unknown>/50%` and `REPLICAS 1`. `<unknown>` means the HPA could not get the metric it needs — it isn't "0% load," it's "I have no number at all." An HPA that can't read its metric doesn't scale; it freezes at the current replica count.

## Read the autoscaler's status

```bash
kubectl describe hpa transcode-scaler -n media
```{{exec}}

Read the `Conditions`. `AbleToScale True` (the HPA can act), but **`ScalingActive False`** with reason **`FailedGetResourceMetric`**, and a message like:

```text
failed to get cpu utilization: missing request for cpu in container app
```

That's the diagnosis in one line. The HPA targets CPU *utilization*, which it computes as `usage ÷ request`. There's no request, so there's no denominator — the calculation is undefined and the HPA reports `<unknown>`. (You may also see `FailedComputeMetricsReplicas` events, which is the same cause one step downstream.)

## Confirm the target has no CPU request

```bash
kubectl get deployment transcode-scaler -n media \
  -o jsonpath='{.spec.template.spec.containers[0].resources}'; echo
```{{exec}}

`{"limits":{"memory":"128Mi"}}` — a memory limit, and nothing else. No `requests.cpu`. Contrast with the workload behind the baseline's *working* HPA, which requests CPU:

```bash
kubectl get deployment sip-router -n signaling \
  -o jsonpath='{.spec.template.spec.containers[0].resources.requests}'; echo
```{{exec}}

`sip-router` has `cpu: 25m` — a denominator — so its HPA reads a real percentage. `transcode-scaler` has none. metrics-server is scraping the Pod fine; the missing piece is the request the percentage is measured against. Add it next.
