# Step 4 — The consumer

The consumer reads the derived Secret like any Secret from M03. It does not know that the operator or the store exist.

## The consumer is running

```bash
kubectl describe deployment billing-processor -n provisioning
```{{exec}}

Read the `Environment:` block. It shows `DB_PASSWORD: <set to the key 'DB_PASSWORD' in secret 'db-credentials'>`. If that Secret were missing, the Pod would sit in `CreateContainerConfigError`.

## The value the process holds

```bash
kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD
```{{exec}}

It prints S3cure-prod-4417, the same value as the store in step 2. The chain holds: store key `db-password`, then the operator, then Secret key `DB_PASSWORD`, then the environment of the running process.

The kubelet set that variable once, when the container started. A later change to the Secret does not reach it. Remember this for the rotation scenarios.

Each break/fix scenario breaks one link in this chain.
