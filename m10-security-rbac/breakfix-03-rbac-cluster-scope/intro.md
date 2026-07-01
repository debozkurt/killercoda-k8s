# M10 — Break/fix 03: RBAC — wrong scope

> Pre-req: break/fix 01–02. You've read a Forbidden where the *verb* was wrong, and one where the *identity* was wrong. This one's *scope* is wrong.

An analytics workload, `node-inspector`, reads the cluster's node inventory — it lists `nodes` to correlate telemetry with the hardware each Pod runs on. It's in `CrashLoopBackOff` with a `403 Forbidden`, and this time whoever set it up clearly tried: there's a ServiceAccount, a Role that names `nodes` with `get`/`list`/`watch`, and a RoleBinding wiring them together. `kubectl get role` shows the grant right there.

Yet the call is still denied. The reason is the one RBAC boundary a Role can't cross. Read the Forbidden all the way to its last words — they say `scope` — and re-grant the access the only way a cluster-scoped resource can be granted.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
