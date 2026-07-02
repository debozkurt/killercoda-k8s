# Step 2 — Fix it and verify

The parent is already gone, so there's no cascade to trigger — the orphan has to be deleted directly. Reclaim its capacity.

## Delete the orphan

```bash
kubectl delete deployment vega-media -n media
```{{exec}}

Its two replicas are released. Because it had no owner, this is a plain, targeted delete — you're removing exactly the leftover, nothing else.

## Verify — and confirm the healthy children are untouched

```bash
kubectl get deployments -n media -l managed-by=tenant-operator
```{{exec}}

`vega-media` is gone; `orion-media` and `lyra-media` remain. Prove they're still properly owned (so *they'll* clean up correctly when their tenants are offboarded):

```bash
kubectl get deployment orion-media -n media -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}'; echo
```{{exec}}

`MediaTenant/orion` — the live children still carry their owner references, so cascading deletion will work for them. Only the un-owned orphan needed manual removal.

The durable fix is upstream: the current operator stamps ownerReferences on everything it creates (that's why `orion-media` and `lyra-media` are safe), so no *new* orphans appear — this one predated that behavior. When you adopt owner-reference stamping, sweep for existing un-owned children once; new ones won't accumulate. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
