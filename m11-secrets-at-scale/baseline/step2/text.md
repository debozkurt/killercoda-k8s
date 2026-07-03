# Step 2 — The materialized Secret: a derived object

The operator turns each SecretSync into an ordinary Kubernetes `Secret` — the thing the consumer actually reads. That Secret is **derived**: the operator owns it and reconciles it back to the store.

## The Secret the operator produced

```bash
kubectl get secret db-credentials -n provisioning -o yaml
```{{exec}}

A normal `Opaque` Secret with key `DB_PASSWORD`, carrying a `managed-by: secret-operator` label — the operator stamps it so you can tell derived Secrets from hand-written ones. Confirm the value matches the store, base64-for-base64:

```bash
echo "store : $(kubectl get secret vault-backend -n secrets-source -o jsonpath="{.data.db-password}" | base64 -d)"
echo "synced: $(kubectl get secret db-credentials -n provisioning -o jsonpath="{.data.DB_PASSWORD}" | base64 -d)"
```{{exec}}

Same value — the operator read `db-password` from the store and wrote it as `DB_PASSWORD` in the target. The `sourceKey → secretKey` rename from the SecretSync is exactly this mapping.

## Derived means don't hand-edit it

Because the operator reconciles this Secret from the store on every pass, editing it by hand is pointless — the next reconcile overwrites it. Change the *source* (the store, or the SecretSync), never the materialized Secret. List everything the operator owns:

```bash
kubectl get secrets -A -l managed-by=secret-operator
```{{exec}}

Both `db-credentials` and `partner-api` — the two Secrets the pipeline produced. These are outputs, not inputs.
