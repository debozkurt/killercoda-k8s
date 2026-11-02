# Step 2 — Fix it and verify

The Secret is already correct. The consumer must start a new container so that the kubelet reads the Secret again.

## Roll the consumer

```bash
kubectl rollout restart deployment/billing-processor -n provisioning
kubectl rollout status deployment/billing-processor -n provisioning
```{{exec}}

`rollout restart` changes a Pod template annotation, so the Deployment replaces its Pod.

## Verify the value

```bash
kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD
```{{exec}}

It prints R0tated-prod-8842, the value in the store. The rotation now reaches the process.

A checksum annotation on the Pod template does not prevent this failure here. The deploy tool computes the checksum when it renders the manifest, and the operator changes the Secret later. For a synced Secret, use a controller that watches the Secret and restarts its consumers.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m11-secrets-at-scale/ANSWER-KEY.md).
