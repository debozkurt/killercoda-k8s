# M16 — Baseline Tour

Every Polyphone environment — `dev`, `lab`, `stage`, `prod`, across four regions — runs *the same* workloads with *different* settings: more replicas in prod, tighter config in lab, region-specific placement. Copy-pasting a full manifest per environment is how drift starts. Kustomize solves this by keeping one **base** and layering environment-specific **overlays** on top, with no templating language — just YAML patched by more YAML.

This scenario gives you a healthy, fully-wired Kustomize setup for one workload, `edge-relay` (an edge SIP/RTP relay in the `edge` namespace), written to `/root/edge-relay`:

- **`base/`** — the environment-agnostic definition: a Deployment, a Service, and a `configMapGenerator` that owns the relay's config
- **`components/regional-affinity/`** — a reusable Component that pins the relay to SSD nodes
- **`overlays/lab/`** and **`overlays/prod/`** — two environments built from the one base

Nothing here is broken. The point is to *see the machine work*: render the base, render both overlays and diff them, apply the prod overlay, and watch how a generated ConfigMap's content hash forces a rollout. The full Polyphone fleet boots alongside it.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
