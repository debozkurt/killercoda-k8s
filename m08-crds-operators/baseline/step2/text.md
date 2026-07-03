# Step 2 — Custom resources: spec you set, status the operator writes

A **custom resource** (CR) is an instance of the CRD's type. Like every Kubernetes object it splits into two halves: `.spec` (desired state, which you declare) and `.status` (observed state, which the controller writes).

## The two tenants

```bash
kubectl get mediatenants -A
```{{exec}}

`orion` (gold, desired 2) and `lyra` (silver, desired 1). Those columns come from the CRD's `additionalPrinterColumns` — `TIER` and `DESIRED` read from `.spec`, `READY` and `PHASE` from `.status`. Both show `PHASE Ready`.

## Read one closely

```bash
kubectl get mediatenant orion -n media -o yaml
```{{exec}}

Two blocks matter. `spec` is what a product team asked for:

```yaml
spec:
  tier: gold
  replicas: 2
```

`status` is what the operator reported back after acting:

```yaml
status:
  phase: Ready
  readyReplicas: 2
```

You wrote `spec`; you never wrote `status`. `status` lives on a separate **subresource** — the operator updates it through `/status`, and a normal `kubectl apply` of the spec can't touch it. That split (you own `spec`, the controller owns `status`) is the contract every operator follows.
