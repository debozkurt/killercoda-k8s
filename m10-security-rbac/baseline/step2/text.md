# Step 2 — What an identity may do: RBAC

An identity is nothing without grants. **RBAC** grants permissions: rules grouped into a **Role**, handed to a subject by a **RoleBinding**.

## The built-in ClusterRoles

```bash
kubectl get clusterroles | grep -E '^(view|edit|admin|cluster-admin) '
```{{exec}}

Four user-facing ClusterRoles ship with every cluster. You grant them per namespace rather than writing rules by hand.

## A Role is rules: apiGroups × resources × verbs

```bash
kubectl describe clusterrole view | head -25
```{{exec}}

Each rule is three lists ANDed: an **apiGroup** (`""` is the core group), a **resource** (`pods`, `endpoints`…), and **verbs** (`get`, `list`, `watch`…). `view` reads most resources — but notice `secrets` is absent (reading Secrets is a privilege escalation).

## What the fleet already has

```bash
kubectl get roles,rolebindings -A | grep -v kube-system | head
```{{exec}}

A handful of system bindings, and not much else — the fleet's Pods don't call the API, so they need no grants.

## Deny-by-default — prove it

```bash
kubectl auth can-i list secrets -n media --as=system:serviceaccount:media:default
kubectl auth can-i get pods    -n media --as=system:serviceaccount:media:default
```{{exec}}

Both `no`. RBAC has no `deny` rule; the *absence* of an allow is the denial. `kubectl auth can-i` asks the API server the exact question the authorizer answers — it's your first move on any `Forbidden`. Every real permission a Pod has comes from a binding you add; nothing is granted by default.
