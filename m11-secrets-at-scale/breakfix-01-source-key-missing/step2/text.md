# Step 2 — Fix it and verify

Correct the reference in the SecretSync — the source, not the derived Secret. The operator picks up the change on its next reconcile; you don't touch the operator or the Pod.

## Fix the source key

Re-apply the `partner-api` SecretSync with the correct `sourceKey`:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: polyphone.example/v1
kind: SecretSync
metadata:
  name: partner-api
  namespace: media
  labels: { plane: media, tier: lab }
spec:
  storeRef: { name: vault-backend }
  target:   { name: partner-api }
  data:
    - { secretKey: API_TOKEN, sourceKey: api-token }
EOF
```{{exec}}

You fix the SecretSync because it's the source of truth for this Secret; editing the Secret directly would be undone on the next reconcile. Watch the sync flip to healthy:

```bash
kubectl get secretsync partner-api -n media
```{{exec}}

Within ~10 seconds `READY` becomes `True`, `REASON` `Synced`. The operator resolved `api-token` and materialized the Secret:

```bash
kubectl get secret partner-api -n media
```{{exec}}

`partner-api` now exists, labeled `managed-by: secret-operator`.

## Verify the consumer recovers

The kubelet retries a `CreateContainerConfigError` Pod on a backoff, so once the Secret exists the container starts on its own — no manual restart:

```bash
kubectl get pods -n media -l app=partner-connector
```{{exec}}

It moves to `Running` `1/1` (allow a few seconds for the kubelet's next retry). Confirm the value reached the process:

```bash
kubectl exec deploy/partner-connector -n media -- printenv API_TOKEN
```{{exec}}

The token from the store, delivered end to end. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
