# Done

The third 403 in a row, and the one whose diagnosis lives in the *last* words of the message. The verb (`list`) was granted and the identity (`node-inspector`) was right — but `nodes` are cluster-scoped, and the grant was written as a namespaced Role + RoleBinding, which can never reach a resource that lives outside every namespace. RBAC accepted the YAML and granted nothing; the Forbidden ended `at the cluster scope`, not `in the namespace`. Re-granting with a ClusterRole + ClusterRoleBinding fixed it.

The rule to keep: **cluster-scoped resources (`nodes`, `namespaces`, `persistentvolumes`, `clusterroles`) can only be granted by a ClusterRole through a ClusterRoleBinding.** A namespaced binding for them parses clean and does nothing — the word `scope` in the error is how you catch it.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § RBAC (the two scopes).
- Next scenario: **`breakfix-04-podsecurity-restricted`** — a different gate entirely: not authorization, but admission.
