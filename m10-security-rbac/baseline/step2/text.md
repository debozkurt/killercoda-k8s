# Step 2 — What an identity may do: RBAC

**RBAC** grants permissions. A **Role** (namespaced) or **ClusterRole** (cluster-wide) holds rules. A **RoleBinding** or **ClusterRoleBinding** grants a role to a subject, such as a ServiceAccount.

## The built-in user-facing ClusterRoles

```bash
kubectl get clusterroles view edit admin cluster-admin
```{{exec}}

Kubernetes ships these four. You grant them per namespace instead of writing rules by hand.

## A rule is API groups × resources × verbs

```bash
kubectl describe clusterrole view | head -30
```{{exec}}

Each row is one rule. Read the `Resources` column: a core-group resource prints bare (`pods`), and any other group prints a suffix (`deployments.apps`). The `Verbs` column reads [get list watch]. A request matches only when the resource, its API group, and the verb all appear in one row.

`view` has no `secrets` row. Reading a Secret can expose ServiceAccount tokens, so `view` leaves Secrets out.

## Deny by default

```bash
kubectl auth can-i get pods -n media --as=system:serviceaccount:media:default
```{{exec}}

The answer is no. RBAC has no deny rule. A request is refused because no rule allows it. Step 3 adds the rule.
