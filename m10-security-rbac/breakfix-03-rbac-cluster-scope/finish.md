# Done

The verb was granted and the identity was correct. The last words of the Forbidden sentence, `at the cluster scope`, held the diagnosis. Nodes belong to no namespace, and the grant was a namespaced Role and RoleBinding. The API server accepted that Role and it granted nothing. A ClusterRole with a ClusterRoleBinding fixed it.

The rule: **only a ClusterRole bound by a ClusterRoleBinding grants a cluster-scoped resource** (`nodes`, `namespaces`, `persistentvolumes`, `clusterroles`). A namespaced grant for one is accepted and does nothing.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-04-podsecurity-restricted`**. A different gate: admission.
