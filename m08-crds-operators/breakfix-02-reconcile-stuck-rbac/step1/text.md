# Step 1 — Diagnose the stuck reconciliation

Confirm the stall in `.status`, rule out a crashed operator, then let the logs name the failing step.

## Tenants stuck, nothing built

```bash
kubectl get mediatenants -A
kubectl get deployments -n media -l managed-by=tenant-operator
```{{exec}}

Both tenants show Provisioning and READY 0. The second command lists no Deployments. The operator never created a child.

## The operator is Running. That proves little.

```bash
kubectl get pods -n platform
kubectl logs deployment/tenant-operator -n platform --tail=12
```{{exec}}

The Pod is `Running` with 0 restarts, so this is not a crash. The logs show the cause on every pass:

```
error: failed to create deployment: deployments.apps is forbidden: User
"system:serviceaccount:platform:tenant-operator" cannot create resource
"deployments" in API group "apps" in the namespace "media"
```

The loop reads the tenants and tries to create their Deployments, and the API server refuses. The operator authenticates as the ServiceAccount `platform:tenant-operator`. That identity lacks the `create` verb.

## Confirm the missing permission

```bash
kubectl auth can-i create deployments -n media \
  --as=system:serviceaccount:platform:tenant-operator
kubectl describe clusterrole tenant-operator
```{{exec}}

The answer is no. In the role's rule list, the `deployments.apps` row grants only `get`, `list` and `watch`. The operator can see Deployments and cannot create them, so reconciliation stops at the first write.
