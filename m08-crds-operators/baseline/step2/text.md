# Step 2 — Custom resources: spec you set, status the operator writes

A **custom resource** (CR) is an object of the type a CRD defines. Like every Kubernetes object it has two halves: `.spec` (desired state, which you declare) and `.status` (observed state, which a controller writes).

## The two tenants

```bash
kubectl get mediatenants -A
```{{exec}}

`orion` (gold, desired 2) and `lyra` (silver, desired 1). The CRD's `additionalPrinterColumns` pick the columns: `TIER` and `DESIRED` come from `.spec`, `READY` and `PHASE` from `.status`. Both tenants show PHASE Ready.

## Read one closely

```bash
kubectl get mediatenant orion -n media -o yaml
```{{exec}}

Read three blocks. `spec` is what a product team asked for: `tier: gold` and `replicas: 2`. `status` is what the operator reported: `phase: Ready` and `readyReplicas: 2`. `metadata.finalizers` holds `polyphone.example/media-cleanup`, a hook the operator adds. Step 5 uses it.

You wrote `spec`. You never wrote `status`. The CRD enables the **status subresource**, a separate write path at `/status`. The operator updates `status` there, and a normal `kubectl apply` of the spec cannot touch it. You own `spec` and the controller owns `status`.
