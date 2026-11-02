# Step 1 — Diagnose the green pipeline

The pipeline reports healthy, so compare values link by link until two disagree.

## The pipeline

```bash
kubectl get secretsync -A
```{{exec}}

Both syncs read Synced. Decode the store value and the derived Secret:

```bash
kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' | base64 -d; echo
kubectl get secret db-credentials -n provisioning -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo
```{{exec}}

Both print R0tated-prod-8842. The store rotated, and the operator synced the new value into the Secret.

## The process

```bash
kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD
```{{exec}}

It prints S3cure-prod-4417, the old password. The Secret and the process disagree.

## Why the process kept the old value

```bash
kubectl describe deployment billing-processor -n provisioning
kubectl get pods -n provisioning -l app=billing-processor
```{{exec}}

The `Environment:` block shows `DB_PASSWORD` set from the key `DB_PASSWORD` in the Secret `db-credentials`. The kubelet sets an environment variable once, at container start, and never updates it. The Pod's `AGE` is older than the rotation, and it has 0 restarts. A change to a Secret never restarts a Pod, and nothing in this cluster watches the Secret to restart it.
