# Step 1 — Diagnose the shared failure

Read the producing objects first. The pattern of failures tells you which link to open.

## The fan-out

```bash
kubectl get secretsync -A
```{{exec}}

Both syncs read `READY` False and `REASON` StoreNotReady. A failure on every sync, in every namespace, points at what they share: the store.

```bash
kubectl describe secretsync db-credentials -n provisioning
```{{exec}}

The `Status:` block reads `Message: cannot read backing store secrets-source/vault-backend`.

## The store and the operator

```bash
kubectl get secret vault-backend -n secrets-source
kubectl get pods -n secrets-system
```{{exec}}

The store exists, and `secret-operator` is `Running` with 0 restarts. A live controller that cannot read an existing object points at its permissions (M10).

## Prove the identity's access

The operator runs as the ServiceAccount `secret-operator` in `secrets-system`. Ask the API server what that identity may do:

```bash
kubectl auth can-i get secrets -n secrets-source \
  --as=system:serviceaccount:secrets-system:secret-operator
```{{exec}}

The answer is no. The store grant comes from one RoleBinding:

```bash
kubectl describe rolebinding secret-operator-store -n secrets-source
kubectl get serviceaccounts -n secrets-system
```{{exec}}

The `Subjects:` row names the ServiceAccount `secret-operator-ro`. No such ServiceAccount exists. The binding grants store access to an identity that nothing runs as.
