# M10 — Break/fix 02: ServiceAccount — running as default

> Pre-req: break/fix 01. You've read one `Forbidden`; this one looks identical until you read *who* it names.

A call-routing workload, `route-watcher`, lists the endpoints in its namespace — the same job `endpoint-watcher` had last time — and it's in the same `CrashLoopBackOff` with the same `403 Forbidden` in its logs. But here the RBAC was set up correctly: there's a dedicated ServiceAccount, a Role that grants `list` on endpoints, and a RoleBinding tying them together.

So why the denial? The answer is in *which identity* the Forbidden names. Read it, prove the RBAC is actually fine with `kubectl auth can-i`, and find the one field on the Pod that sends every call out under the wrong name. Fix the Pod, not the RBAC.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
