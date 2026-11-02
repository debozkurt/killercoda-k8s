# Step 2 — Fix it and verify

Add the missing verb to the Role. The ServiceAccount, the RoleBinding, and the application stay as they are.

## Add list to the Role

```bash
kubectl patch role endpoint-reader -n media --type=json \
  -p '[{"op":"replace","path":"/rules/0/verbs","value":["get","list","watch"]}]'
```{{exec}}

Or with an editor: `kubectl edit role endpoint-reader -n media`, then set the verbs to get, list, watch.

## Verify the decision

```bash
kubectl auth can-i list endpoints -n media --as=system:serviceaccount:media:endpoint-watcher
```{{exec}}

The answer is yes. The API server applies RBAC changes on the next request.

## Clear the backoff

The kubelet still waits out the crash-loop backoff before the next restart. Start a new Pod instead of waiting:

```bash
kubectl rollout restart deployment endpoint-watcher -n media
kubectl rollout status deployment endpoint-watcher -n media --timeout=60s
kubectl logs -n media deploy/endpoint-watcher --tail=2
```{{exec}}

The log shows HTTP 200, and the Pod stays `Running`. The Role changed and the application did not. For self-grading, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m10-security-rbac/ANSWER-KEY.md).
