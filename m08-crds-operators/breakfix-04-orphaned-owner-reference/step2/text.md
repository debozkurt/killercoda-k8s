# Step 2 — Fix it and verify

The parent is gone, so no cascade can run. Delete the orphan yourself.

## Delete the orphan

```bash
kubectl delete deployment vega-media -n media
```{{exec}}

The delete frees the two replicas. Because the Deployment has no owner, this removes exactly the leftover.

## Verify, and check the healthy children

```bash
kubectl get deployments -n media -l managed-by=tenant-operator
kubectl get deployment orion-media -n media -o yaml | head -n 30
```{{exec}}

`vega-media` is gone. `orion-media` and `lyra-media` remain, and `orion-media` still shows its `ownerReferences`, so the collector will clean it up when its tenant leaves.

The durable fix is upstream. The current operator stamps a reference on everything it creates, so no new orphans appear. Sweep for older un-owned children once.
