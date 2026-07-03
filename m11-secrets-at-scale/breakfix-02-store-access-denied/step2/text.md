# Step 2 — Fix it and verify

Point the store RoleBinding at the identity the operator actually uses. You don't restart the operator — its loop retries every few seconds and picks up the restored access on its own.

## Bind the correct ServiceAccount

Re-apply the RoleBinding with the right subject (`secret-operator`):

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-operator-store
  namespace: secrets-source
  labels: { plane: security, tier: lab }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: secret-operator-secrets
subjects:
  - kind: ServiceAccount
    name: secret-operator
    namespace: secrets-system
EOF
```{{exec}}

Confirm the operator's identity can now read the store:

```bash
kubectl auth can-i get secrets -n secrets-source \
  --as=system:serviceaccount:secrets-system:secret-operator
```{{exec}}

`yes`. Grant store-read to *only* the operator's ServiceAccount — a store is a shared dependency, so its access list is high-value; keep it to exactly the identity that needs it.

## Verify the whole pipeline recovers

Within ~10 seconds the operator's next pass reads the store and materializes both Secrets:

```bash
kubectl get secretsync -A
kubectl get secrets -A -l managed-by=secret-operator
```{{exec}}

Both syncs flip to `Synced`, and `db-credentials` and `partner-api` appear. The consumers recover as the kubelet retries them:

```bash
kubectl get pods -n provisioning -l app=billing-processor
kubectl get pods -n media -l app=partner-connector
```{{exec}}

Both move to `Running` `1/1` (allow a few seconds). One binding fixed, and every consumer that depended on the store is back. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
