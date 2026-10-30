# Step 1 — Diagnose the stalled operator

The tenants exist and the operator runs. Compare the symptom with the previous scenario, then read the logs.

## The same symptom, with blank status

```bash
kubectl get mediatenants -A
kubectl get deployments -n media -l managed-by=tenant-operator
kubectl get pods -n platform
```{{exec}}

`PHASE` and `READY` are blank. The operator never wrote `.status`, so it never reached the tenants. No Deployments exist. The Pod is `Running`.

## Rule out RBAC

```bash
kubectl auth can-i create deployments -n media \
  --as=system:serviceaccount:platform:tenant-operator
kubectl auth can-i list mediatenants.polyphone.example \
  --as=system:serviceaccount:platform:tenant-operator
```{{exec}}

Both answers are yes. The operator may do everything its loop needs, so permissions are not the cause. Read the logs:

```bash
kubectl logs deployment/tenant-operator -n platform --tail=8
```{{exec}}

Each pass logs `cannot list mediatenants.v1.polyphone.example`, followed by the error. The loop asks for version `v1` of the type, and that request fails. It never reads a single tenant.

## Read the CRD's versions

```bash
kubectl describe crd mediatenants.polyphone.example
```{{exec}}

Under `Versions:` read each `Name:`, `Served:` and `Storage:` line. Version `v1` has `Served: false`. Version `v2` is served and stored. A release retired `v1`, and the operator still reads it.
