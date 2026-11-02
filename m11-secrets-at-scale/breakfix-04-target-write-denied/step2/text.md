# Step 2 — Fix it and verify

Create the write grant in the namespace where the Secret lives. Then remove the inert binding.

## Bind in provisioning

```bash
kubectl create rolebinding secret-operator-targets -n provisioning \
  --clusterrole=secret-operator-secrets \
  --serviceaccount=secrets-system:secret-operator
kubectl delete rolebinding secret-operator-targets -n secrets-system
kubectl auth can-i create secrets -n provisioning \
  --as=system:serviceaccount:secrets-system:secret-operator
```{{exec}}

The answer is now yes. The ClusterRole holds the rules, and each RoleBinding confines them to one namespace.

## Verify the pipeline

```bash
sleep 12
kubectl get secretsync -A
kubectl get secret db-credentials -n provisioning
```{{exec}}

Both syncs read Synced, and the Secret exists. The kubelet starts the consumer on its next retry:

```bash
kubectl get pods -n provisioning -l app=billing-processor
```{{exec}}

The Pod reads `Running` and 1/1. If it still waits, run the command again after 20 seconds.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m11-secrets-at-scale/ANSWER-KEY.md).
