# M10 — Break/fix 02: ServiceAccount — running as default

> Pre-req: break/fix 01. You have read one Forbidden sentence. This one looks the same until you read the identity.

A call-routing workload, `route-watcher`, lists the endpoints in its namespace. It is in `CrashLoopBackOff` with a `403 Forbidden` in its logs. This time the RBAC looks complete: a dedicated ServiceAccount, a Role that grants `list` on endpoints, and a RoleBinding that ties them together.

Read which identity the Forbidden names. Prove whether the RBAC is correct with `kubectl auth can-i`. Then find the one field that sends every call under the wrong identity.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
