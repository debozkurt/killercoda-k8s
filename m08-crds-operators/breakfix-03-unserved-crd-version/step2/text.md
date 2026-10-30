# Step 2 — Fix it and verify

Two repairs exist. The durable one upgrades the operator to read `v2`. The immediate one serves `v1` again, so every consumer that still uses it works. Use the immediate repair here.

## Serve v1 again

```bash
kubectl patch crd mediatenants.polyphone.example --type=json \
  -p='[{"op":"replace","path":"/spec/versions/0/served","value":true}]'
kubectl describe crd mediatenants.polyphone.example
```{{exec}}

Both versions now show `Served: true`. Storage stays on `v2`. The API server converts between the two versions, and in this CRD the schemas match, so only the `apiVersion` changes.

## Verify reconciliation resumes

```bash
sleep 15
kubectl get mediatenants -A
kubectl logs deployment/tenant-operator -n platform --tail=6
```{{exec}}

The tenants move to `Ready`, the Deployments appear, and the error stops. The operator did not change. Its CRD version became available again.
