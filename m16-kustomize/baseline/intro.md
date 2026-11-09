# M16 — Baseline Tour

> Pre-req: M03 (ConfigMaps and `envFrom`) and M04 (labels and selectors).

Every Polyphone environment runs the same workloads with different settings: more replicas in prod, other config values in lab, placement per region. Kustomize keeps one **base** and describes each environment as an **overlay** on top of it. It has no templating language. YAML changes YAML, and `kubectl` has it built in.

This scenario writes a healthy Kustomize tree for one workload, `edge-relay`, to `/root/edge-relay`:

- **`base/`** — a Deployment, a Service, and a `configMapGenerator` that builds the relay's config
- **`components/regional-affinity/`** — an optional change that pins the relay to SSD nodes
- **`overlays/lab/`** and **`overlays/prod/`** — two environments built from the one base

The setup already applied the prod overlay. Nothing is broken. You render the base, compare the overlays, compare prod with the live cluster, and then change one config value and follow it into a rollout.

The cluster takes 60 to 120 seconds to start. Click **Start** when ready.
