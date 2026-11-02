# M10 — Break/fix 03: RBAC — wrong scope

> Pre-req: break/fix 01 and 02. You have fixed a wrong verb and a wrong identity. This denial has neither.

An analytics workload, `node-inspector`, lists the cluster's nodes to match telemetry to hardware. It is in `CrashLoopBackOff` with a `403 Forbidden`. The setup looks complete: a ServiceAccount, a Role that names `nodes` with get, list, and watch, and a RoleBinding that ties them together.

The call is still denied. Read the Forbidden sentence to its last words, then grant the access in the one way a cluster-scoped resource accepts.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
