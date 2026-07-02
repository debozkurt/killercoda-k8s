# M10 — Break/fix 01: RBAC — a missing verb

> Pre-req: the M10 baseline tour. You've seen ServiceAccounts, RBAC, and `kubectl auth can-i`; this is the first denial.

A media discovery workload, `endpoint-watcher`, was rolled out to the `media` namespace to list the fleet's Service endpoints. It won't stay up — the Pod is in `CrashLoopBackOff`, restart count climbing. But this isn't an app crash: the container's own logs show a `403 Forbidden` from the API server.

The workload runs under its own ServiceAccount, which someone bound to a Role for reading endpoints. Yet one specific call is denied. Your job: read the Forbidden — it names the identity, the verb, and the resource — then read the Role that identity was granted and find why the two don't line up. Fix the RBAC, not the app.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
