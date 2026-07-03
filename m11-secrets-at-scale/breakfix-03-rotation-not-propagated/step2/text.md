# Step 2 — Fix it and verify

The Secret is already correct, so there's nothing to change in the pipeline — you just need the consumer to re-read it. Rolling the Deployment restarts its Pods, and each new container reads the current Secret at start.

## Roll the consumer

```bash
kubectl rollout restart deployment/billing-processor -n provisioning
```{{exec}}

`rollout restart` replaces the Pod with a fresh one; you don't touch the Secret or the pipeline, because they're already right. Wait for the new Pod:

```bash
kubectl rollout status deployment/billing-processor -n provisioning
```{{exec}}

## Verify the new value landed

Read what the process holds now, and compare it to the store:

```bash
echo "store: $(kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.db-password}' | base64 -d)"
echo "proc : $(kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD)"
```{{exec}}

Both `R0tated-prod-8842` — the rotation finally reached the running process. The fix wasn't in the store, the SecretSync, or the Secret; it was the missing second step: rolling the consumers after the value changed.

For a durable version of this, you'd stop hand-rolling: annotate the Pod template with a hash of the Secret so a change rolls the Deployment automatically, or run a controller that watches the Secret and restarts consumers on change. Rotation becomes two coupled steps instead of one you can forget. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
