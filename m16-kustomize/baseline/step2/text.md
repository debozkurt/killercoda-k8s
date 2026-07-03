# Step 2 — Two overlays, one base

An **overlay** is a kustomization whose `resources:` points at a base (or another overlay) and then layers changes on top. Same base, different result per environment. Read the lab overlay first — it's almost nothing:

```bash
cat overlays/lab/kustomization.yaml
```{{exec}}

Lab pulls in `../../base` and adds a `tier: lab` label. That's it — lab is deliberately close to the source of truth. Now the prod overlay, which is where the real layering happens:

```bash
cat overlays/prod/kustomization.yaml
```{{exec}}

Prod pulls in the same base and adds four kinds of change: a **component** (`components:`), a **transformer** each for labels and images, a **generator merge** (`configMapGenerator` with `behavior: merge`), and a **patch** (`patches:`). Each is a distinct Kustomize mechanism; you'll meet all four across this module's break/fix scenarios.

## Render both and diff them

The base never changed. Everything below is produced by the overlays:

```bash
diff <(kubectl kustomize overlays/lab) <(kubectl kustomize overlays/prod)
```{{exec}}

Walk the differences:

- **`replicas: 1` → `replicas: 3`** — the prod `patches:` entry (a strategic-merge patch in `replicas-patch.yaml`) overrides the base's replica count.
- **`image: nginx:1.25` → `nginx:1.27`** — the prod `images:` transformer pins a different tag without editing the Deployment YAML.
- **`MAX_SESSIONS: "500"` → `"5000"`**, **`LOG_LEVEL: info` → `warn`** — the prod `configMapGenerator` merge overrode two values; `REGION` stayed, inherited from the base.
- **`nodeAffinity:`** appears only in prod — that's the `regional-affinity` component, wired in by prod and skipped by lab.
- The ConfigMap **hash differs** between the two — different content, different name.

## The mental model

One base is the single source of truth. Each overlay is a small, reviewable diff describing how *that* environment departs from it. Nothing is copy-pasted; a fix to the base reaches every environment on the next render. This is why GitOps repos are built on Kustomize (or Helm) rather than per-environment folders of full manifests — you'll wire it into Flux in M18.

Nothing is applied yet. Step 3 pushes the prod overlay to the cluster.
