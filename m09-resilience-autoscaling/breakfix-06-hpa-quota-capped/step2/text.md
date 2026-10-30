# Step 2 — Fix it and verify

The cap must cover the HPA maximum, with room for a rolling update's surge. The maximum is 8.

## Raise the cap

```bash
kubectl patch resourcequota pod-cap -n captions --type merge -p '{"spec":{"hard":{"pods":"10"}}}'
kubectl describe resourcequota pod-cap -n captions
```{{exec}}

Hard now reads 10. The ReplicaSet controller retries a failed create with a growing delay, and a quota change does not wake it. Nudge it with a restart, which creates a fresh ReplicaSet:

```bash
kubectl rollout restart deployment/caption-engine -n captions
kubectl rollout status deployment/caption-engine -n captions --timeout=120s
```{{exec}}

## Verify

```bash
kubectl get deployment caption-engine -n captions
kubectl get hpa -n captions
```{{exec}}

READY reads 4/4, and REPLICAS on the HPA matches MINPODS.

A full node leaves Pods `Pending` with `FailedScheduling`. A quota leaves Pods uncreated, with `FailedCreate` on the ReplicaSet. Size the quota from the HPA maximum, or the autoscaler's ceiling is a lie.

See [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m09-resilience-autoscaling/ANSWER-KEY.md) for self-grading, then `finish.md`.
