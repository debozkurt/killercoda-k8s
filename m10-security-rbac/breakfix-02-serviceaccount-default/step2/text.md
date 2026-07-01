# Step 2 — Fix it and verify

The Role and RoleBinding are correct for the `route-watcher` SA — the Pod just never adopted it. Point the Pod at the right identity.

## Set the Pod's ServiceAccount

```bash
kubectl set serviceaccount deployment route-watcher route-watcher -n call-routing
```{{exec}}

Or by hand:

```bash
kubectl edit deployment route-watcher -n call-routing
# under spec.template.spec: add  serviceAccountName: route-watcher
```

This changes the Pod template, so the Deployment rolls a new Pod — one that authenticates as `route-watcher`, the SA the RoleBinding actually grants.

## Verify the Pod's identity, then its health

```bash
kubectl get deploy route-watcher -n call-routing \
  -o jsonpath='{.spec.template.spec.serviceAccountName}'; echo
kubectl rollout status deployment route-watcher -n call-routing --timeout=60s
```{{exec}}

`route-watcher`, and the rollout completes. Confirm the reader now gets through:

```bash
kubectl get pods -n call-routing -l app=route-watcher
kubectl logs -n call-routing deploy/route-watcher --tail=4
```{{exec}}

`Running`, and the logs show `HTTP 200`. Note what you did *not* do: you didn't touch the Role, the RoleBinding, or grant `default` anything. The RBAC was correct all along — "fixing" it by granting `default` the permission would have handed that access to every other Pod in the namespace. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
