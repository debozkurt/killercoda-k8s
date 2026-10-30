# Step 2 — The Horizontal Pod Autoscaler

A **HorizontalPodAutoscaler** (HPA) watches a metric and changes a Deployment's replica count to hold the metric near a target. The baseline ships one on `sip-router`.

## Read the autoscaler

```bash
kubectl get hpa -n signaling
```{{exec}}

`TARGETS` reads current CPU utilization over the target, for example 3%/50%. `MINPODS` and `MAXPODS` are 2 and 6. If `TARGETS` reads `<unknown>` right after boot, metrics-server has not reported its first sample. Wait 30 seconds and run the command again.

## Read the calculation

```bash
kubectl describe hpa sip-router -n signaling
```{{exec}}

Read two blocks. The `Metrics:` line says resource cpu on pods (as a percentage of request). Utilization is usage divided by the container's CPU **request**, the amount it reserves. `sip-router` requests 25m, so a few milli-cores of idle load is a few percent.

The `Conditions:` block shows `ScalingActive True`. The HPA can read the metric and compute a replica count. With no CPU request, there is no percentage to compute, and this condition turns `False`.

## The loop

About every 15 seconds the HPA reads the metric and computes:

```text
desiredReplicas = ceil( currentReplicas × currentMetric ÷ target )
```

It clamps the result between the minimum and the maximum, then writes the Deployment's replica field. The ReplicaSet does the rest. Next: push the HPA past its target.
