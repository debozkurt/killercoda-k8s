# Step 1 — Diagnose the green-but-stale consumer

The pipeline reports healthy, so don't look for a broken link — look for the gap between what the Secret holds and what the process holds. That gap is the whole failure.

## The pipeline is green

```bash
kubectl get secretsync -A
```{{exec}}

Both `Synced`, `READY True`. No error anywhere in the pipeline. The materialized Secret holds the current store value:

```bash
echo "store : $(kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' | base64 -d)"
echo "secret: $(kubectl get secret db-credentials -n provisioning -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)"
```{{exec}}

Both show `R0tated-prod-8842` — the store rotated, and the operator synced the new value into the Secret. The supply chain is correct end to end. So why is the app failing?

## Read what the process actually has

The Secret is right; check the value the *running container* is holding:

```bash
kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD
```{{exec}}

`S3cure-prod-4417` — the **old** password. The Secret says one thing, the process says another. That's the tell: this consumer reads `DB_PASSWORD` as an **environment variable**, and env vars are materialized once, at container start, and frozen for the life of the container (M03). The Pod started before the rotation and captured the old value; the Secret updating underneath it changed nothing in the running process.

## Confirm nothing rolled the Pod

```bash
kubectl get pods -n provisioning -l app=billing-processor
```{{exec}}

One Pod, old `AGE`, 0 restarts — it has been running since before the rotation. A Secret changing never restarts a Pod, and no controller watches the Secret to do it for you. The rotation reached the Secret and stopped there. To make it land, the consumer has to be rolled so it re-reads the Secret at a fresh container start.
