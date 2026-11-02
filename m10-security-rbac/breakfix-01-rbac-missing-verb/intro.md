# M10 — Break/fix 01: RBAC — a missing verb

> Pre-req: the M10 baseline. You have read ServiceAccounts, RBAC, and `kubectl auth can-i`. This is the first denial.

A discovery workload, `endpoint-watcher`, lists the Service endpoints in the `media` namespace. Its Pod is in `CrashLoopBackOff` and the restart count climbs. The application has no bug: its own logs show a `403 Forbidden` from the API server.

The workload runs under its own ServiceAccount, and a RoleBinding grants that account a Role for endpoints. One call is still denied. Read the Forbidden sentence, then read the Role, and find the field that does not match. Fix the RBAC, not the application.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
