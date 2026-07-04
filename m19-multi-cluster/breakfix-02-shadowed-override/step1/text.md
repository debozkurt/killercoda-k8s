# Step 1 — Find the layer that's winning

Confirm the disagreement. The region overlay says one thing; the render says another:

```bash
cd /root/fleet
grep MAX_SESSIONS regions/us-east-1/kustomization.yaml
kubectl kustomize clusters/prod-us-east-1 | grep MAX_SESSIONS
```{{exec}}

The region file sets `8000`; the cluster renders `5000`. The value you'd fix is already correct — so something later in the path is overriding it.

## Grep the whole path, take the last writer

`MAX_SESSIONS` could be set in any of three layers. List every one that touches it, in composition order — base, region, leaf:

```bash
grep -rn MAX_SESSIONS base regions/us-east-1 clusters/prod-us-east-1
```{{exec}}

Three hits: `base` sets `500`, `regions/us-east-1` sets `8000`, and `clusters/prod-us-east-1` sets `5000`. Composition order is base → region → cluster, and **the last layer to write a field wins**. The cluster overlay writes last, so its `5000` shadows the region's `8000`. That's why editing the region changed nothing — a more-specific layer sits on top of it.

## Read the shadow

Look at the leaf that's doing the overriding:

```bash
cat clusters/prod-us-east-1/kustomization.yaml
```{{exec}}

There's a per-cluster `configMapGenerator` merge pinning `MAX_SESSIONS=5000` — a leftover from an earlier capacity plan, before the standard moved to the region layer. It was never removed, so it silently wins over every regional update. The owning layer is correct; this leftover is shadowing it. On to the fix.
