# M08 — Baseline Tour

Everything you've run so far is a *built-in* resource type — Pods, Deployments, Services — served by the API server out of the box. Kubernetes also lets you add your own types, and lets you write a program that gives them meaning. That pairing is an **operator**: a **CustomResourceDefinition** (CRD) registers a new resource type, and a **controller** watches instances of it and drives the cluster to match.

Polyphone's platform team ships one. Product teams don't hand-write Deployments to get media capacity — they create a **MediaTenant**, a custom resource that declares a tier and a replica count. The **tenant-operator** control loop notices each MediaTenant, creates a child media Deployment sized to match, links that child back to the MediaTenant with an **ownerReference**, and writes the result into the MediaTenant's `.status`. Declared intent in, running capacity out.

This tour runs on the full Polyphone fleet on a **2-node cluster** (one tainted control-plane, one worker), plus the CRD, the operator, and two healthy MediaTenants (`orion`, `lyra`). Nothing is broken — you're learning to *read* a working operator before the break/fix scenarios break it.

Four short steps:

1. **The CRD** — the new `MediaTenant` type, and how `kubectl` treats it exactly like a built-in
2. **Custom resources** — the two MediaTenants: the `.spec` you declare vs. the `.status` the operator writes
3. **The operator reconciling** — the child Deployments it created, and reading operator-managed state from status, events, and logs
4. **Owner references** — the parent→child link that lets cascading deletion clean up automatically

See what a healthy operator looks like, so a stuck one stands out later. The cluster takes 90–150 seconds to come up (the operator needs a few more seconds to reconcile). Click **Start** when ready.
