# Step 3 — Resource metrics: `kubectl top`

The first metrics pipeline is the **Resource Metrics API**: `metrics-server` scrapes each kubelet for live CPU and memory and serves it on `metrics.k8s.io`. `kubectl top` reads it.

## Node and Pod usage, right now

```bash
kubectl top nodes
```{{exec}}

(If it says "Metrics API not available," metrics-server is still starting — wait ~30s and retry.) CPU and memory in use per node, against capacity.

```bash
kubectl top pods -A --sort-by=memory | head -12
```{{exec}}

Live per-Pod memory, biggest first. This is the same data the **HPA** scales on — it divides a Pod's live usage by its **request** to get utilization (M09), which is why a metric is only meaningful measured against the request you set in M06.

## Read one workload against its request

```bash
kubectl top pod -n media -l app=session-broker
kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].spec.containers[0].resources.requests}'; echo
```{{exec}}

Usage from `top`, the request from the spec — "how loaded is this" is the ratio of the two.

## Know the pipeline's limits

This pipeline is deliberately minimal: **CPU and memory only**, **right now only**, no history, no custom numbers. It answers "how loaded is this?" and feeds the HPA — nothing more. No metrics-server, and both `kubectl top` and the HPA go dark (the HPA reads `<unknown>`) — same pipeline, same failure.

Anything richer — calls per second, queue depth, error rate — comes from a *different* pipeline, the one your workloads publish about themselves. That's next.
