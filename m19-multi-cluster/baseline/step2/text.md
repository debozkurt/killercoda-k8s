# Step 2 — Cluster vars and the rendering trace

A **cluster variable** is any value that makes one cluster or region differ from the identical majority — `REGION`, `tier`, replica count, capacity. The rule that keeps a fleet legible: each variable has exactly one owning layer. Render two clusters and diff them to see where the differences live:

```bash
cd /root/fleet
diff <(kubectl kustomize clusters/prod-us-east-1) <(kubectl kustomize clusters/prod-eu-central-1)
```{{exec}}

Same tier (`prod`), same replica count, different region. Walk the differences:

- **`REGION: us-east-1` → `eu-central-1`** and **`MAX_SESSIONS: "8000"` → `"4000"`** — both set by the **region** overlay. Two clusters, two regions, and the region-scoped vars flip together because they share one owning layer.
- The ConfigMap **hash differs** — different content (different `REGION`/`MAX_SESSIONS`), so a different name.
- `tier: prod` and `replicas: 3` are the **same** — those come from the leaf, and both leaves pin the same tier and count.

## Trace a value to its layer

The render is ground truth, but it doesn't say *which layer* produced a value. To attribute one, grep the whole path. Follow `MAX_SESSIONS` for `prod-us-east-1`:

```bash
grep -rn MAX_SESSIONS base regions/us-east-1 clusters/prod-us-east-1
```{{exec}}

Two layers touch it: `base` sets `500` (the fleet floor), `regions/us-east-1` merges `8000`. The leaf doesn't set it. **Composition order** is base → region → cluster, and the last layer to write a field wins — so `8000` survives to the render:

```bash
kubectl kustomize clusters/prod-us-east-1 | grep MAX_SESSIONS
```{{exec}}

That is the entire trace algorithm: render the value, grep each layer in the path, the last one that sets it is the winner. The base's `500` is never seen here because the region overrides it — it's the default a region inherits only if it says nothing.

## Why the names must match

The generator merges across three layers only because every layer names it `edge-relay-config`. That's the same name-match rule from M16, now operating up the stack — break the name in any layer and the merge (and the reference rewrite) silently stops. Step 3 moves from config vars to the image, and to promotion.
