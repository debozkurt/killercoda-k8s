# Step 2 — Fix it and verify

Point the RoleBinding at the identity that the operator runs as. Keep the grant in `secrets-source` only. A ClusterRoleBinding would also clear the symptom, and it would let the operator read every Secret in the cluster. The operator retries every 10 seconds, so it needs no restart.

## Fix the subject

```bash
kubectl patch rolebinding secret-operator-store -n secrets-source --type=json \
  -p '[{"op":"replace","path":"/subjects/0/name","value":"secret-operator"}]'
kubectl auth can-i get secrets -n secrets-source \
  --as=system:serviceaccount:secrets-system:secret-operator
```{{exec}}

The answer is now yes.

## Verify the pipeline

```bash
sleep 12
kubectl get secretsync -A
kubectl get secrets -A -l managed-by=secret-operator
```{{exec}}

Both syncs read Synced, and both Secrets exist. The kubelet now starts both consumers on its next retry:

```bash
kubectl get pods -n provisioning -l app=billing-processor
kubectl get pods -n media -l app=partner-connector
```{{exec}}

Both read `Running` and 1/1. If a Pod still waits, run the commands again after 20 seconds.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m11-secrets-at-scale/ANSWER-KEY.md).
