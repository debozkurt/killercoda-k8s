# Step 2 — Fix it and verify

The HPA needs a CPU request on the target to compute utilization against. Add one — that's the entire fix.

## Add a CPU request

```bash
kubectl set resources deployment/transcode-scaler -n media --requests=cpu=100m
```{{exec}}

This edits the Pod template and triggers a quick rolling update to a Pod that now declares `requests.cpu: 100m`. (`kubectl edit deployment transcode-scaler -n media` and adding the request by hand does the same thing.)

## Verify the autoscaler recovers

The HPA re-reads on its next loop, and metrics-server needs a sample of the new Pod — give it 15–30 seconds, then look:

```bash
kubectl get hpa transcode-scaler -n media
```{{exec}}

`TARGETS` now shows a real number — something like `1%/50%` — instead of `<unknown>`. The autoscaler is computing utilization again. Confirm its condition flipped:

```bash
kubectl describe hpa transcode-scaler -n media | grep -A5 Conditions
```{{exec}}

`ScalingActive True` — the HPA is live. With idle load it holds at `minReplicas` (1); drive CPU past 50% of the request and it would scale toward `maxReplicas` (5).

## Why a request, not a limit

The percentage is measured against the **request**, not the limit — the request is the "expected" size the autoscaler treats as 100%. That's why the memory *limit* the container already had didn't help: it's the wrong resource and the wrong field. Two things to carry forward:

- **CPU-utilization HPAs require a CPU request on every container in the Pod.** No request is the single most common reason an HPA reads `<unknown>`. Enforce requests with a `LimitRange` or admission policy (M20) so an autoscaled workload can't ship without one.
- **Size the request honestly.** The target percentage is relative to the request, so a too-small request makes the workload look busier than it is (HPA over-scales); a too-large one hides real load (HPA under-scales). The request is both the scheduler's reservation (M06) *and* the autoscaler's yardstick.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
