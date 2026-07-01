# M05 — Break/fix 03: RWO Volume Can't Span Two Nodes

> Pre-req: the M05 baseline tour and break/fix 01–02. You've split "claim `Pending`" from "claim absent"; this is the third case — claim `Bound`, Pod still stuck.

`directory` in `app-services` was scaled to 2 replicas for headroom. One came up; the other is stuck and won't schedule. Run `get pvc` and the claim, `directory-data`, is `Bound` — so this isn't break/fix 01 (`Pending` claim) or break/fix 02 (absent claim). The storage exists and bound cleanly. And yet a Pod can't start.

That combination — a `Bound` claim with a Pod still stuck — is the signature of an *attach* problem, and the cause is the access mode. `directory-data` is `ReadWriteOnce`: it can be mounted on one node at a time. Two replicas were forced onto two different nodes, and the second one can't attach a volume that's already committed to the first node's.

Your job: recognize the `Bound`-but-stuck shape, read the scheduling failure, and stop asking one RWO volume to back Pods on two nodes. The cluster takes up to ~2–3 minutes to come up (one replica stays stuck by design). Click **Start** when ready.
