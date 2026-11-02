# Step 1 — Diagnose the one-namespace failure

Read the producing objects first. The failure pattern narrows the link before you open any detail.

## The pattern

```bash
kubectl get pods -n provisioning -l app=billing-processor
kubectl get secretsync -A
```{{exec}}

The Pod reads `CreateContainerConfigError`. `db-credentials` reads `REASON` SecretWriteError, and `partner-api` reads Synced. The store read works, because `partner-api` synced from the same store. The failure is in what the operator does in `provisioning`.

```bash
kubectl describe secretsync db-credentials -n provisioning
kubectl logs deployment/secret-operator -n secrets-system --tail=4
```{{exec}}

The `Status:` block reads `Message: cannot write target Secret provisioning/db-credentials`. The log line for `db-credentials` carries the API server's refusal: the operator's ServiceAccount is forbidden on `secrets` in the namespace `provisioning`.

## Prove the identity's access

```bash
kubectl auth can-i create secrets -n provisioning \
  --as=system:serviceaccount:secrets-system:secret-operator
kubectl auth can-i create secrets -n media \
  --as=system:serviceaccount:secrets-system:secret-operator
```{{exec}}

no for `provisioning`, yes for `media`. Find the write grants:

```bash
kubectl get rolebindings -A | grep secret-operator
```{{exec}}

`secret-operator-targets` exists in `media` and in `secrets-system`, not in `provisioning`. A RoleBinding grants only inside its own namespace (M10). Someone created the `provisioning` grant next to the operator's ServiceAccount, so it grants writes in `secrets-system`, where no `SecretSync` lives.
