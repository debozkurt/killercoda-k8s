# Step 2 — Fix it and verify

Set every field the violation lists. Change the workload, not the namespace label.

busybox runs as root by default, so the patch also sets `runAsUser: 1000`. Without it, admission accepts the Pod and the kubelet refuses to start it.

## Add the securityContext

```bash
kubectl patch deployment payments-api -n payments -p '{
  "spec": {"template": {"spec": {
    "securityContext": {"runAsNonRoot": true, "runAsUser": 1000, "seccompProfile": {"type": "RuntimeDefault"}},
    "containers": [{"name": "app", "securityContext": {"allowPrivilegeEscalation": false, "capabilities": {"drop": ["ALL"]}}}]
  }}}
}'
```{{exec}}

This is a strategic merge patch. kubectl merges the `containers` entry into the existing container named `app`, so the image and command stay.

## Verify

```bash
kubectl rollout status deployment payments-api -n payments --timeout=60s
kubectl get deploy,pods -n payments
```{{exec}}

A Pod exists and is `Running`, and the Deployment reads 1/1. For self-grading, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m10-security-rbac/ANSWER-KEY.md).
