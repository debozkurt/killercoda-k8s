# M10 — Break/fix 05: RBAC — wrong API group

> Pre-req: break/fix 01 to 03. You have read the verb, identity, and scope fields of the Forbidden sentence. This scenario breaks the remaining one.

A release auditor, `release-auditor`, lists the Deployments in the `provisioning` namespace and reports their image versions. It is in `CrashLoopBackOff` with a `403 Forbidden`. The RBAC looks right at a glance: a dedicated ServiceAccount, a RoleBinding, and a Role that grants get, list, and watch on `deployments`.

The verb is there, the identity is correct, and the scope is the namespace. Read the one field left, then compare it with the rule.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
