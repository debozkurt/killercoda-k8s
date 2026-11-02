# Step 3 — The operator's report

The operator is a controller, so it reports on two channels: the `.status` of each object it reconciles, and its own logs (M08). Read both before you look at a consumer Pod.

## The operator is running

```bash
kubectl get pods -n secrets-system
```{{exec}}

`secret-operator` is `Running` with 0 restarts. That proves the process is alive. It does not prove the process did its job.

## The sync result

```bash
kubectl describe secretsync db-credentials -n provisioning
```{{exec}}

Read the `Status:` block at the bottom. `Ready: True`, `Reason: Synced`, `Synced Keys: DB_PASSWORD`, and a `Message:` that names the Secret it wrote. A failed sync reads `Ready: False` with one of three other reasons:

```text
SyncError          a source key is missing from the store
StoreNotReady      the operator cannot read the store
SecretWriteError   the operator cannot write the target Secret
```

## The operator's logs

```bash
kubectl logs deployment/secret-operator -n secrets-system --tail=6
```{{exec}}

One `Synced ->` line per `SecretSync` per pass. The loop runs every 10 seconds and re-reads the store each time, so a store change reaches the Secret on the next pass with no restart.
