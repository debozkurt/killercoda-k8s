# Step 1 — Diagnose the Forbidden

Third 403. The verb is granted and the identity is right — so read the message to its very end.

## Confirm it's crashing

```bash
kubectl get pods -n analytics -l app=node-inspector
```{{exec}}

`CrashLoopBackOff`. Read the logs.

## The scope, not the verb, is the tell

```bash
kubectl logs -n analytics deploy/node-inspector --tail=8
```{{exec}}

```text
GET /api/v1/nodes -> HTTP 403
{... "message":"nodes is forbidden: User
\"system:serviceaccount:analytics:node-inspector\" cannot list resource
\"nodes\" in API group \"\" at the cluster scope","reason":"Forbidden", ...}
```

The identity is right (`node-inspector`) and the verb is `list` — which the Role *does* grant. But the message doesn't end `in the namespace "analytics"` like the last two did; it ends **`at the cluster scope`**. `nodes` are a cluster-scoped resource — they don't live in any namespace — and that changes what kind of grant can reach them.

## Prove the namespaced grant does nothing

```bash
kubectl auth can-i list nodes \
  --as=system:serviceaccount:analytics:node-inspector          # no
```{{exec}}

`no`, even though the Role and RoleBinding exist. Look at what kind of objects they are:

```bash
kubectl get role,rolebinding -n analytics | grep node
```{{exec}}

A **Role** and a **RoleBinding** — both namespaced. And confirm `nodes` really is cluster-scoped:

```bash
kubectl api-resources --namespaced=false | grep -E 'NAME|nodes'
```{{exec}}

`nodes` shows `NAMESPACED = false`. A namespaced RoleBinding only grants within its namespace, so it can never reach a resource that lives outside every namespace. The YAML parsed fine; the grant is simply inert. On to the fix.
