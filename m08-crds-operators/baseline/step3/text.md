# Step 3 — The operator reconciling: reading operator-managed state

The `.status` from the last step didn't fill itself in. A **controller** — the tenant-operator, running as an ordinary Pod — watched the MediaTenants and made the cluster match them.

## The operator is just a Pod

```bash
kubectl get pods -n platform
```{{exec}}

`tenant-operator` is `Running`. It authenticates to the API as its own ServiceAccount and runs a **reconcile loop**: read every MediaTenant, ensure a matching child exists, write status, repeat.

## What it created

```bash
kubectl get deployments -n media -l managed-by=tenant-operator
```{{exec}}

`orion-media` (2 replicas) and `lyra-media` (1) — the operator created these from the tenants' `spec.replicas`. You never applied them; the loop did.

## Watch it work, in its own logs

```bash
kubectl logs deployment/tenant-operator -n platform --tail=6
```{{exec}}

Lines like `orion/orion: phase=Ready readyReplicas=2 desired=2` — one reconcile pass per tenant, every few seconds. When you debug an operator, its **logs** are the primary interface: they show what it observed and what it did. Reading operator-managed state means reading three things together — the CR's `.status`, the child resources, and these logs.
