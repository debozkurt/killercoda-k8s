# Step 2 — Fix it and verify

Give the Pod a `securityContext` that satisfies every line of the violation. These are exactly the `restricted` fields.

## Add the securityContext

```bash
kubectl patch deployment payments-api -n payments -p '{
  "spec": {"template": {"spec": {
    "securityContext": {"runAsNonRoot": true, "runAsUser": 1000, "seccompProfile": {"type": "RuntimeDefault"}},
    "containers": [{"name": "app", "securityContext": {"allowPrivilegeEscalation": false, "capabilities": {"drop": ["ALL"]}}}]
  }}}
}'
```{{exec}}

This is a strategic-merge patch, so the `containers` entry merges into the existing container named `app` by name — it keeps the image and command and only adds the container-level `securityContext`. The pod-level block (`runAsNonRoot`, `runAsUser`, `seccompProfile`) covers the rest.

Or by hand:

```bash
kubectl edit deployment payments-api -n payments
# add under spec.template.spec:
#   securityContext: { runAsNonRoot: true, runAsUser: 1000, seccompProfile: { type: RuntimeDefault } }
# add under the container (spec.template.spec.containers[0]):
#   securityContext: { allowPrivilegeEscalation: false, capabilities: { drop: ["ALL"] } }
```

## Verify

```bash
kubectl rollout status deployment payments-api -n payments --timeout=60s
kubectl get pods -n payments
```{{exec}}

A Pod now exists and goes `Running` — admission accepted it because it meets `restricted`. Confirm the Deployment is healthy:

```bash
kubectl get deploy payments-api -n payments
```{{exec}}

`1/1` available. Nothing about the app changed; you gave the Pod the security posture the namespace requires. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
