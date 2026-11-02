# Step 1 — Diagnose the missing Secret

Start at the consumer, then climb to the object that should have produced its Secret.

## The consumer

```bash
kubectl get pods -n media -l app=partner-connector
kubectl describe pod -n media -l app=partner-connector
```{{exec}}

`STATUS` reads `CreateContainerConfigError`. The last event reads `Error: secret "partner-api" not found`. The kubelet cannot build the container's environment, because the Secret behind `API_TOKEN` does not exist.

In M03 you would create the Secret. This Secret is derived, so a hand-written copy would be overwritten by the operator. Find out why the operator did not write it.

## The producing object

```bash
kubectl get secretsync -A
```{{exec}}

`partner-api` reads `READY` False and `REASON` SyncError. `db-credentials` reads Synced. One sync failed, so the store and the operator work. The fault is inside this one object.

```bash
kubectl describe secretsync partner-api -n media
```{{exec}}

The `Status:` block reads `Message: source keys not found in store: api-tokn`. Under `Spec:`, `Data:` reads `Source Key: api-tokn`.

## The store

```bash
kubectl describe secret vault-backend -n secrets-source
```{{exec}}

The store's keys are `api-token`, `db-password`, and `signing-key`. The `SecretSync` names `api-tokn`, a typo. The operator refuses to write a partial Secret, so it wrote none.
