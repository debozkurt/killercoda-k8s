# Step 2 — Two overlays, one base

An **overlay** is a kustomization whose `resources:` list names a base, and then changes the result.

```bash
cat overlays/lab/kustomization.yaml
```{{exec}}

Lab includes `../../base` and adds a `tier: lab` label with `includeSelectors: false`. That flag keeps the label off every selector.

```bash
cat overlays/prod/kustomization.yaml
```{{exec}}

Prod uses five mechanisms on the same base:

- `components:` includes the `regional-affinity` component
- `labels:` adds `tier: prod`
- `images:` changes the nginx tag
- `configMapGenerator` with `behavior: merge` overrides two keys of the base generator
- `patches:` applies `replicas-patch.yaml`, a partial Deployment named `edge-relay`

## Diff the two renders

```bash
diff <(kubectl kustomize overlays/lab) <(kubectl kustomize overlays/prod)
```{{exec}}

Match each difference to its mechanism:

- `replicas: 1` becomes `replicas: 3`: the patch.
- `image: nginx:1.25` becomes `nginx:1.27`: the `images` transformer.
- `LOG_LEVEL` and `MAX_SESSIONS` change, and `REGION` stays: the generator merge.
- The `affinity:` block appears only in prod: the component.
- The ConfigMap hash differs, because the data differs.
- `tier: lab` becomes `tier: prod`: the label transformer.

The base did not change. Each overlay is a small, reviewable statement of how one environment departs from it.
