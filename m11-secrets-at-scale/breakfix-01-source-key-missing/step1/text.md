# Step 1 — Diagnose the missing Secret

Confirm the consumer's failure, notice the Secret is absent, then let the SecretSync's status name the failing step instead of guessing at the Pod.

## The consumer can't start

```bash
kubectl get pods -n media -l app=partner-connector
```{{exec}}

`CreateContainerConfigError`. That's the M03 shape for a missing env reference — the kubelet tried to build the container's environment and couldn't. Read why:

```bash
kubectl describe pod -n media -l app=partner-connector | grep -A3 -i 'Warning\|Error'
```{{exec}}

`Error: secret "partner-api" not found`. The Secret the Pod's `API_TOKEN` comes from doesn't exist:

```bash
kubectl get secret partner-api -n media
```{{exec}}

`NotFound`. In M03 you'd stop here and create it. But this Secret is *derived* — the operator materializes it from a SecretSync — so creating it by hand would just be overwritten. Find out why the pipeline didn't produce it.

## The SecretSync says why

```bash
kubectl get secretsync -A
```{{exec}}

`partner-api` reads `READY False`, `REASON SyncError`, while `db-credentials` is `Synced`. So this is one broken sync, not a store-wide outage. Read the detail:

```bash
kubectl get secretsync partner-api -n media -o jsonpath='{.status.message}'; echo
```{{exec}}

`source keys not found in store: api-tokn`. The operator read the store fine but couldn't find the key this sync named. Compare what it asks for against what the store actually has:

```bash
kubectl get secretsync partner-api -n media -o jsonpath='{.spec.data}'; echo
kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data}'; echo
```{{exec}}

The sync names `sourceKey: api-tokn`; the store's keys are `db-password`, `api-token`, `signing-key`. It's a typo — `api-tokn` should be `api-token`. Because the key doesn't resolve, the operator refuses to materialize a partial Secret, so `partner-api` is never created and the consumer can't start.
