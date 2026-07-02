# Step 2 — The Horizontal Pod Autoscaler

Rolling updates change *which version* runs. The **Horizontal Pod Autoscaler (HPA)** changes *how many* run — it watches a metric and adjusts the Deployment's replica count to keep that metric near a target. The baseline ships one on `sip-router`.

## Read the autoscaler

```bash
kubectl get hpa -n signaling
```{{exec}}

The `TARGETS` column reads something like `3%/50%` — current CPU utilization over the target. `MINPODS`/`MAXPODS` are `2`/`6`, and `REPLICAS` is the count the HPA currently wants. If `TARGETS` shows `<unknown>` right after boot, metrics-server hasn't reported its first sample yet — wait 15–30s and re-run. (An autoscaler stuck at `<unknown>` for a *different* reason is breakfix-02.)

## How it computes that percentage

CPU utilization isn't raw CPU — it's usage as a fraction of the **request**. The pipeline: metrics-server scrapes each Pod's live usage, the HPA reads it from the metrics API, and divides by the container's CPU *request* to get a percentage. `sip-router` requests `25m`; at a few milli-cores of idle load, that's a few percent. `describe` shows the whole calculation and the decisions:

```bash
kubectl describe hpa sip-router -n signaling
```{{exec}}

Read the `Conditions` block: `AbleToScale True`, `ScalingActive True`, `ScalingLimited`. `ScalingActive True` means the HPA is successfully reading the metric and computing a desired replica count. The `Metrics` line shows `resource cpu on pods (as a percentage of request)` — note *as a percentage of request*. That denominator is the whole game: no CPU request, no percentage, no scaling.

## The control loop

The HPA runs a loop (about every 15 seconds): read the metric, compute `desiredReplicas = ceil(currentReplicas × currentMetric ÷ targetMetric)`, and clamp it between `minReplicas` and `maxReplicas`. Push real load through `sip-router` and this number climbs; remove it and the HPA scales back down (after a stabilization window, so it doesn't flap).

The HPA sets the Deployment's replica count — which then rolls out through the same ReplicaSet mechanics from step 1. Autoscaling and rolling updates aren't separate systems; the autoscaler just drives the same replica field you'd set by hand. Next: protecting those replicas during a disruption.
