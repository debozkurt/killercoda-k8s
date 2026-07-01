# M24 — Break/fix 03: No Leader Ever Elected (Leader-Election RBAC)

> Pre-req: the M24 baseline tour. You've read a healthy Lease and checked the RBAC that lets its holder renew it; this is what happens when that permission is missing.

`call-coordinator` in `call-routing` is a 2-replica active/standby singleton — exactly one replica should hold leadership and make global routing decisions, the other standing by. Its Pods are both `Running`, nothing is crashing, and at a glance it looks healthy. But nothing is actually happening: no replica has become the leader, so the singleton work never runs. The workload is *up but idle*.

That's the trap in this failure — Pod health tells you nothing, because the problem isn't the Pods. Leadership in Kubernetes is a lock on a `Lease` object, and taking that lock requires permission. Your job: confirm no leader was elected, prove *why* the election client can't acquire the lock, and restore the permission it needs. The cluster takes 2–3 minutes to come up. Click **Start** when ready.
