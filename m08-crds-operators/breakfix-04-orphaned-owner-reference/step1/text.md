# Step 1 — Diagnose the orphan

`vega-media` runs and its tenant is gone. Confirm that, then compare its owner references with a healthy child's.

## A child with no living parent

```bash
kubectl get mediatenants -A
kubectl get deployments -n media -l managed-by=tenant-operator
```{{exec}}

Two tenants, `orion` and `lyra`. Three Deployments: `vega-media` runs beside the two legitimate children. The operator will not remove it, because no `vega` tenant exists for it to reconcile.

## Compare the owner references

```bash
kubectl get deployment orion-media -n media -o yaml | head -n 30
kubectl get deployment vega-media -n media -o yaml | head -n 30
```{{exec}}

In `metadata`, `orion-media` has an `ownerReferences` block: `kind: MediaTenant`, `name: orion`, `controller: true`. `vega-media` has no `ownerReferences` field at all.

## Why that blocks cleanup

When you delete an owner, the **garbage collector** finds every object whose `ownerReferences` names that owner, and deletes it too. `vega-media` never had that field. An older operator created it before the operator stamped references. When `vega` was deleted, nothing linked the two objects. The tenant went and the Deployment stayed. The fix is to delete the orphan directly.
