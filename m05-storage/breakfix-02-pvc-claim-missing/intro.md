# M05 — Break/fix 02: Pod Names a Claim That Isn't There

> Pre-req: the M05 baseline tour and break/fix 01. You've seen a claim stuck `Pending`; this is a claim that isn't stuck — it's absent.

`directory` in `app-services` is stuck `Pending` and never started. It looks like break/fix 01 at first glance — a Pod waiting on storage — but the shape is different. This time `describe pod` names the exact cause, and it isn't a class or a binding problem.

The Pod is asking for a claim that *doesn't exist*. The Pod↔PVC link is by name, in the same namespace, and if that name doesn't match a real claim, the Pod waits forever for a volume that was never requested. This is the second leaf of the differential: the claim the Pod names is not `Pending` — it's *absent*.

Your job: read what the Pod is actually mounting, compare it to the claims that exist, and point the Pod at the right one. The cluster takes up to ~2–3 minutes to come up (one workload stays Pending by design). Click **Start** when ready.
