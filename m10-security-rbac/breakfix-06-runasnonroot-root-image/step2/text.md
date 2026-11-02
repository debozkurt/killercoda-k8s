# Step 2 — Fix it and verify

Give the process a non-root user. Keep `runAsNonRoot: true`: it is the check that caught the root image, and `restricted` requires it.

## Set runAsUser

```bash
kubectl patch deployment ledger-sync -n payments -p '{
  "spec": {"template": {"spec": {"securityContext": {"runAsUser": 1000}}}}
}'
kubectl rollout status deployment ledger-sync -n payments --timeout=60s
```{{exec}}

The patch merges `runAsUser: 1000` into the existing Pod-level block. The other way to fix it is an image that declares a numeric non-root `USER`. A non-numeric `USER` (a name) fails the same check, because the kubelet cannot prove the name is not root.

## Verify

```bash
kubectl get deploy,pods -n payments
kubectl exec -n payments deploy/ledger-sync -- id -u
```{{exec}}

The Pod is `Running`, the Deployment reads 1/1, and `id -u` prints 1000. For self-grading, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m10-security-rbac/ANSWER-KEY.md).
