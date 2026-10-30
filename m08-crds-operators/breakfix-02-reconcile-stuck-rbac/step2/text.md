# Step 2 — Fix it and verify

Give the ClusterRole the write verbs the loop needs. Do not restart the operator. The loop retries every 10 seconds, so it uses the new permission on its next pass.

## Grant the missing verbs

```bash
kubectl edit clusterrole tenant-operator
```{{exec}}

Add `create`, `update`, `patch` and `delete` to the verbs of the `deployments` rule, then save. Prefer a one-liner? This patch does the same:

```bash
kubectl patch clusterrole tenant-operator --type=json -p='[{"op":"replace","path":"/rules/2/verbs","value":["get","list","watch","create","update","patch","delete"]}]'
```{{exec}}

Grant only the verbs the loop uses. An operator's role should be as narrow as its job. Confirm:

```bash
kubectl auth can-i create deployments -n media \
  --as=system:serviceaccount:platform:tenant-operator
```{{exec}}

## Verify reconciliation resumes

```bash
sleep 15
kubectl get mediatenants -A
kubectl logs deployment/tenant-operator -n platform --tail=6
```{{exec}}

Both tenants move to `Ready`, and the forbidden errors stop. The Pod did not change. The same process works because it holds the permission it lacked.
