# Step 2 — Fix it and verify

Put the rule in the `apps` group. The verbs, resource, ServiceAccount, and binding stay.

## Correct the API group

```bash
kubectl patch role release-reader -n provisioning --type=json \
  -p '[{"op":"replace","path":"/rules/0/apiGroups","value":["apps"]}]'
kubectl describe role release-reader -n provisioning
```{{exec}}

The rule row now reads `deployments.apps`.

```bash
kubectl auth can-i list deployments -n provisioning --as=system:serviceaccount:provisioning:release-auditor
```{{exec}}

The answer is yes.

## Clear the backoff and verify

```bash
kubectl rollout restart deployment release-auditor -n provisioning
kubectl rollout status deployment release-auditor -n provisioning --timeout=60s
kubectl logs -n provisioning deploy/release-auditor --tail=2
```{{exec}}

The log shows HTTP 200. To write a rule for any resource, read its group from `kubectl api-resources` first. For self-grading, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m10-security-rbac/ANSWER-KEY.md).
