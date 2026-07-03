# Step 1 — Diagnose the orphan

`vega-media` runs, but its parent tenant is gone. Confirm that, then compare its owner references to a healthy child's to see why cascading deletion skipped it.

## A child with no living parent

```bash
kubectl get mediatenants -A
```{{exec}}

Only `orion` and `lyra` — no `vega`. Yet its Deployment is still here:

```bash
kubectl get deployments -n media -l managed-by=tenant-operator
```{{exec}}

`vega-media` is `Running`, 2 replicas, alongside the two legitimate children. The operator won't remove it — there's no `vega` MediaTenant for it to reconcile, and the loop only manages children of tenants that exist. So why didn't the garbage collector clean it up when `vega` was deleted?

## Compare the owner references

A healthy child points back at its MediaTenant. Read one:

```bash
kubectl get deployment orion-media -n media -o jsonpath='{.metadata.ownerReferences}'; echo
```{{exec}}

`orion-media` carries an ownerReference: `kind: MediaTenant, name: orion, controller: true`. Now the orphan:

```bash
kubectl get deployment vega-media -n media -o jsonpath='{.metadata.ownerReferences}'; echo
```{{exec}}

Empty. `vega-media` has **no** ownerReferences at all.

## Why that means no cleanup

Cascading deletion works off ownerReferences: when you delete an owner, the **garbage collector** finds every object whose `ownerReferences` names it and deletes them too. `vega-media` never had that link — it was created out-of-band (by an older operator that didn't stamp owner references), so when `vega` was deleted there was nothing tying the two together. The MediaTenant went; its "child" stayed, now a permanent orphan. `orion-media` would be collected automatically because its ownerReference makes it findable; `vega-media` won't, because nothing points anywhere. The fix is to remove the orphan directly.
