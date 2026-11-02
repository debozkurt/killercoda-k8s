# Step 1 — The pipeline inputs

A secrets pipeline has two inputs: a **backing store** that holds the values, and a **`SecretSync`** that names what to copy. A `SecretSync` is a custom resource, so `kubectl get` and `describe` work on it like on any built-in kind.

## The SecretSyncs

```bash
kubectl get secretsync -A
```{{exec}}

Two rows, `db-credentials` in `provisioning` and `partner-api` in `media`. Each reads `READY` True and `REASON` Synced. `STORE` and `TARGET` come from `.spec`. `READY` and `REASON` come from the `.status` that the operator writes.

```bash
kubectl describe secretsync db-credentials -n provisioning
```{{exec}}

Under `Spec:`, read three blocks. `Data:` maps `Source Key: db-password` to `Secret Key: DB_PASSWORD`. `Store Ref:` names `vault-backend`. `Target:` names `db-credentials`. The object names a key and holds no value, so it is safe to commit to Git.

## The backing store

```bash
kubectl describe secret vault-backend -n secrets-source
```{{exec}}

The `Data` section lists three keys, `api-token`, `db-password`, and `signing-key`, each with a size in bytes. `describe` never prints Secret values. The store holds more keys than any one consumer needs, and each `SecretSync` copies only the keys it names. No Pod mounts this Secret. Only the operator reads it.
