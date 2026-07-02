# Step 1 — Diagnose the stuck reconciliation

Confirm the stall in the custom resources' status, rule out a crashed operator, then let the operator's logs name the failing step.

## The tenants are stuck, with nothing built

```bash
kubectl get mediatenants -A
```{{exec}}

Both `orion` and `lyra` show `PHASE Provisioning`, `READY 0`. And the capacity they represent isn't there:

```bash
kubectl get deployments -n media -l managed-by=tenant-operator
```{{exec}}

No resources — the operator never created a child Deployment for either tenant.

## The operator is Running — that's not the same as working

```bash
kubectl get pods -n platform
```{{exec}}

`tenant-operator` is `Running`, 0 restarts. So this isn't a crash or a CrashLoop. A controller that's up but making no progress points at what it's *allowed to do*, not whether it's alive. Ask it directly:

```bash
kubectl logs deployment/tenant-operator -n platform --tail=12
```{{exec}}

Between the reconcile lines, every pass logs a denial:

```
Error from server (Forbidden): deployments.apps is forbidden: User
"system:serviceaccount:platform:tenant-operator" cannot create resource
"deployments" in API group "apps" in the namespace "media"
```

The loop runs, reads the tenants, and tries to create their child Deployments — but the API server refuses. The operator authenticates as the ServiceAccount `platform:tenant-operator`, and that identity lacks permission to create Deployments.

## Confirm the missing permission

```bash
kubectl auth can-i create deployments -n media \
  --as=system:serviceaccount:platform:tenant-operator
```{{exec}}

`no`. Look at what its ClusterRole actually grants on deployments:

```bash
kubectl get clusterrole tenant-operator \
  -o jsonpath='{range .rules[?(@.resources[0]=="deployments")]}{.verbs}{"\n"}{end}'
```{{exec}}

`["get","list","watch"]` — read-only. The operator can *see* Deployments but not *create* them, so reconciliation stalls at the first write. The fix is to grant the verbs its loop needs.
