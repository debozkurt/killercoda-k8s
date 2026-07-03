# Step 1 — The pipeline inputs: store and SecretSyncs

A secrets pipeline has two declarative inputs: a **backing store** (where the real secret lives) and a **`SecretSync`** that names what to pull from it. Neither contains a secret in a form you'd hesitate to commit.

## The SecretSyncs

```bash
kubectl get secretsync -A
```{{exec}}

Two syncs — `db-credentials` (`provisioning`) and `partner-api` (`media`) — each `READY True`, `REASON Synced`. The `STORE` and `TARGET` columns come from `.spec`; `READY`/`REASON` from the `.status` the operator wrote. This is the pipeline reporting itself healthy.

Read one sync's spec — it *names* store keys, it doesn't contain them:

```bash
kubectl get secretsync db-credentials -n provisioning -o jsonpath='{.spec}'; echo
```{{exec}}

`storeRef: vault-backend`, a `data` mapping `sourceKey: db-password` → `secretKey: DB_PASSWORD`, and `target: db-credentials`. Nothing secret is in this object — it's safe to commit to Git, which is the whole point.

## The backing store

The store is a Secret in `secrets-source`, standing in for an external manager like Vault:

```bash
kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data}'; echo
```{{exec}}

Three keys — `db-password`, `api-token`, `signing-key` — base64-encoded (a Secret, so not encryption; M03). The store holds more than any one consumer needs; each SecretSync pulls only the keys it names. This Secret is wired into no Pod directly — only the operator reads it.
