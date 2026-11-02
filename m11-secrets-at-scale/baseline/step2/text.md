# Step 2 — The derived Secret

The operator writes an ordinary Secret for each `SecretSync`. That Secret is **derived**: the operator controls its content.

## The Secret the operator wrote

```bash
kubectl describe secret db-credentials -n provisioning
```{{exec}}

Read two lines. `Labels:` includes `managed-by=secret-operator`, which marks the Secret as derived. Under `Data`, `DB_PASSWORD` shows its size in bytes.

To compare values you need the value itself. Decode one key from each end:

```bash
kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' | base64 -d; echo
kubectl get secret db-credentials -n provisioning -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo
```{{exec}}

Both lines print S3cure-prod-4417. The operator read `db-password` from the store and wrote it as `DB_PASSWORD`. That rename is the `sourceKey` to `secretKey` mapping from step 1. Base64 hid nothing: one pipe to `base64 -d` printed the password.

## Every derived Secret

```bash
kubectl get secrets -A -l managed-by=secret-operator
```{{exec}}

Two Secrets, `db-credentials` and `partner-api`. These are outputs of the pipeline. To change one, change the store or the `SecretSync`, never the Secret.
