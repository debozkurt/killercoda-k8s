# Done

You read each gate in its healthy state:

- Fleet Pods run as their namespace's `default` ServiceAccount, which holds almost no permissions.
- RBAC grants by rule, and a RoleBinding to a ClusterRole confines the grant to one namespace.
- The fleet runs as root with an empty `securityContext`.
- PodSecurity `enforce` rejects a bare Pod outright, while a bare Deployment gets a warning and then zero Pods.

**Next:**

- Read [`LESSON.md`](../LESSON.md) for the model behind each gate.
- Work the break/fix scenarios. 01, 02, 03 and 05 each break one field of the Forbidden sentence (verb, identity, scope, API group). 04 and 06 split pod security between admission and the kubelet.
- Check each path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
