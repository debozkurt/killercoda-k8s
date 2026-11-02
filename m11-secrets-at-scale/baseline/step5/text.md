# Step 5 — Prove the Secret is derived

A derived Secret follows its source, not your edits. Edit it by hand and watch the operator put it back.

## Edit the Secret

`stringData` takes a plain value, and the API server encodes it into `data`:

```bash
kubectl patch secret db-credentials -n provisioning --type=merge -p '{"stringData":{"DB_PASSWORD":"hand-edited"}}'
kubectl get secret db-credentials -n provisioning -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo
```{{exec}}

It prints hand-edited. The edit landed. (If it already prints the original value, the operator ran a pass between the two commands.)

## Wait one reconcile pass

The operator loop runs every 10 seconds. The wait gives it one pass.

```bash
sleep 15
kubectl get secret db-credentials -n provisioning -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo
```{{exec}}

It prints S3cure-prod-4417 again. The operator re-read the store and re-applied the Secret. The External Secrets Operator does the same: it watches the target Secret, detects the changed data, and rewrites it.

```bash
kubectl get secretsync db-credentials -n provisioning
```{{exec}}

`REASON` still reads Synced. The status never showed the edit, because the edit was not in the pipeline. To change a derived value, change the store or the `SecretSync`.
