# Step 1 — Diagnose the Forbidden

The verb is granted and the identity is right. Read the scope.

## Read the logs

```bash
kubectl get pods -n analytics -l app=node-inspector
kubectl logs -n analytics deploy/node-inspector --tail=8
```{{exec}}

```text
nodes is forbidden: User "system:serviceaccount:analytics:node-inspector"
cannot list resource "nodes" in API group "" at the cluster scope
```

The identity is `node-inspector` and the verb is `list`, which the Role grants. The sentence does not end `in the namespace "analytics"`. It ends `at the cluster scope`.

## Confirm that nodes are cluster-scoped

```bash
kubectl api-resources --namespaced=false | grep -w nodes
```{{exec}}

`nodes` appears in the list of resources that belong to no namespace.

## Read the grant

```bash
kubectl get role,rolebinding -n analytics
kubectl auth can-i list nodes --as=system:serviceaccount:analytics:node-inspector
```{{exec}}

The grant is a **Role** and a **RoleBinding**. Both are namespaced. A RoleBinding grants only inside its own namespace, and nodes are in no namespace. The API server accepted the Role, and the Role grants nothing. `auth can-i` has no `-n` because the question is cluster-scoped, and it answers no.
