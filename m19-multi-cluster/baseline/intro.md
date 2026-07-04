# M19 — Baseline Tour

Polyphone doesn't run a cluster — it runs a fleet: several tiers (`lab`, `stage`, `prod`) crossed with regions (`us-east-1`, `eu-central-1`), dozens of clusters that must be *nearly* identical. Same workloads, differing only where they must: region placement, tier capacity, the image currently under test. M16 gave you base plus overlay for one workload in one place. A fleet is that idea under load, and the source of truth is one git repo describing every cluster at once.

This scenario gives you a healthy fleet repo for one workload, `edge-relay` (an edge SIP/RTP relay in the `edge` namespace), written to `/root/fleet`:

- **`base/`** — the fleet-wide contract: a Deployment, a Service, and a `configMapGenerator` with default config every cluster shares
- **`regions/us-east-1/`** and **`regions/eu-central-1/`** — region overlays that own region-scoped values (`REGION`, regional capacity)
- **`clusters/{lab,stage,prod}-us-east-1/`** and **`clusters/prod-eu-central-1/`** — the leaves; each composes a region overlay and pins its tier, replicas, and image

Nothing here is broken. The point is to *see the machine work*: read the three-layer tree, render two clusters and trace where each field came from, watch how the image `1.27` has been promoted through lab and stage but not yet prod, and apply one cluster. Killercoda gives you a single cluster, so you render the whole fleet and apply the one you inspect. The full Polyphone fleet boots alongside it.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
