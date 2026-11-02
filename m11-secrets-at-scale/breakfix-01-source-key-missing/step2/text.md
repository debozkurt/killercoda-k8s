# Step 2 — Fix it and verify

Fix the reference in the `SecretSync`, which is the source of the Secret. Leave the store, the operator, and the Pod alone.

## Correct the source key

```bash
kubectl patch secretsync partner-api -n media --type=json \
  -p '[{"op":"replace","path":"/spec/data/0/sourceKey","value":"api-token"}]'
```{{exec}}

The operator reads the change on its next pass, within 10 seconds.

```bash
sleep 12
kubectl get secretsync -A
kubectl get secret partner-api -n media
```{{exec}}

`partner-api` reads Synced, and the Secret exists.

## Verify the consumer

The kubelet retries a container in `CreateContainerConfigError` with a backoff. It starts the container once the Secret exists, with no restart from you.

```bash
kubectl get pods -n media -l app=partner-connector
kubectl exec deploy/partner-connector -n media -- printenv API_TOKEN
```{{exec}}

The Pod reads `Running` and 1/1. The process holds the token from the store. If the Pod still waits, run the first command again after 20 seconds.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m11-secrets-at-scale/ANSWER-KEY.md).
