# Step 3 — The operator: reading operator-managed state

Nobody typed the `.status` from step 2. A **controller**, the tenant-operator, watched the tenants and made the cluster match them.

## The operator is a Pod

```bash
kubectl get pods -n platform
```{{exec}}

`tenant-operator` is `Running`. It authenticates as its own ServiceAccount, the identity a Pod uses to call the API. Its **reconcile loop** reads every MediaTenant, makes the cluster match, writes `.status`, and repeats every 10 seconds.

## What it created

```bash
kubectl get deployments -n media -l managed-by=tenant-operator
```{{exec}}

`orion-media` (2 replicas) and `lyra-media` (1). The operator created both from `spec.replicas`. You never applied them.

## Its logs

```bash
kubectl logs deployment/tenant-operator -n platform --tail=6
```{{exec}}

Each line reads like `media/orion: phase=Ready readyReplicas=2 desired=2`: one pass per tenant. The first line names the CRD version the loop reads, `v1`. The break/fix scenarios return to that line.

When you debug an operator, read three places together: the custom resource's `.status`, the child resources, and the operator's logs. Healthy means all three agree.
