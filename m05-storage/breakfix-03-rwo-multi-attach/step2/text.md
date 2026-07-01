# Step 2 — Fix it and verify

An RWO volume backs a single node's Pods. The workload asked two nodes to share one — so the immediate fix is to stop doing that: run a single node-bound consumer. Scale back to one replica.

## Scale to a single consumer

```bash
kubectl scale deployment directory -n app-services --replicas=1
```{{exec}}

The stuck replica is removed, and the one that's left runs on the node that holds `directory-data` — a single RWO consumer on the volume's node, which is exactly what the access mode allows.

## Verify

```bash
kubectl rollout status deployment directory -n app-services --timeout=60s
kubectl get pods -n app-services -l app=directory -o wide
```{{exec}}

One `Running`, `Ready` Pod, no stuck replica — the Deployment is fully available again, and the `directory-data` volume never had to move.

## The real-world version

Scaling to one is the fix *here*, but it's a constraint you should understand, not a workaround to reach for reflexively. `ReadWriteOnce` means one node at a time — full stop. If `directory` genuinely needed several replicas on several nodes all writing shared data, no amount of scheduling would make an RWO volume do it; you'd need a `ReadWriteMany` volume backed by network file storage (NFS, or a CSI driver that supports RWX), which many replicas on many nodes can mount at once. And if each replica needs its *own* durable volume rather than a shared one, that's a StatefulSet with `volumeClaimTemplates` (M07) — one PVC per Pod, no sharing, no conflict. Match the access mode and the volume topology to how the workload actually uses its data. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
