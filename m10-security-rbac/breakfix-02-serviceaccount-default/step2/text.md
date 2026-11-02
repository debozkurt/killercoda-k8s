# Step 2 — Fix it and verify

Point the Pod at the account the RoleBinding grants. Do not change the Role, the RoleBinding, or `default`.

## Set the ServiceAccount

```bash
kubectl set serviceaccount deployment route-watcher route-watcher -n call-routing
kubectl rollout status deployment route-watcher -n call-routing --timeout=60s
```{{exec}}

The command sets `serviceAccountName` in the Pod template. A template change starts a rollout, and the new Pod authenticates as `route-watcher`.

Or with an editor: `kubectl edit deployment route-watcher -n call-routing`, then add `serviceAccountName: route-watcher` under `spec.template.spec`.

## Verify

```bash
kubectl describe pod -n call-routing -l app=route-watcher | grep -m1 'Service Account'
kubectl logs -n call-routing deploy/route-watcher --tail=2
```{{exec}}

`Service Account:  route-watcher`, and the log shows HTTP 200.

A grant to `default` would also clear the error. It would also give the same access to every other Pod in `call-routing` that omits `serviceAccountName`. For self-grading, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m10-security-rbac/ANSWER-KEY.md).
