# Step 2 — Fix it and verify

Loosening the budget would hide the fault. Repair the probe so the replicas become Ready.

## Correct the probe path

```bash
kubectl patch deployment trunk-monitor -n signaling --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/"}]'
kubectl rollout status deployment/trunk-monitor -n signaling --timeout=90s
```{{exec}}

The patch changes the Pod template, so the Deployment rolls out new Pods. They answer the probe with 200 and become Ready. The controller removes the old unready Pods as the new ones come up.

## Verify the budget opened

```bash
kubectl get pods -n signaling -l app=trunk-monitor
kubectl get pdb trunk-monitor -n signaling
```{{exec}}

Both Pods read 1/1, and ALLOWED DISRUPTIONS reads 1. Current is 2, desired is 1, and the drain can proceed.

## The safety net

A fully broken workload should not block maintenance on its own broken Pods. The PDB field `unhealthyPodEvictionPolicy: AlwaysAllow` lets the eviction API remove unready Pods whatever the budget says. It is on by default in this cluster's version. Set it with `kubectl patch pdb trunk-monitor -n signaling --type merge -p '{"spec":{"unhealthyPodEvictionPolicy":"AlwaysAllow"}}'`. Treat it as a net, not a fix: it does not make the workload healthy, and it does not open the budget for the Pods that are Ready.

See [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m09-resilience-autoscaling/ANSWER-KEY.md) for self-grading, then `finish.md`.
