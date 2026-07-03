# Step 4 — The consumer: the chain end to end

The consumer is the point of it all. It reads the materialized Secret as an ordinary env var and never knows the operator, the store, or the SecretSync exist. Trace the value all the way from store to running process.

## The consumer is running on the synced Secret

```bash
kubectl get pods -n provisioning -l app=billing-processor
```{{exec}}

`billing-processor` `Running`, `1/1`. It references the `db-credentials` Secret exactly like any Secret from M03 — `env.valueFrom.secretKeyRef` — so if that Secret were missing, this Pod would be in `CreateContainerConfigError`. It isn't, because the operator produced it.

## The value the process actually got

```bash
kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD
```{{exec}}

The credential the process is holding. Now compare it to the store, the far end of the chain:

```bash
kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' | base64 -d; echo
```{{exec}}

Identical. The full chain held: store `db-password` → operator → `db-credentials` Secret `DB_PASSWORD` → the process's environment. That's a healthy secrets pipeline, top to bottom. Every break/fix scenario snaps exactly one link in this chain — internalize the whole shape so a broken link is obvious.
