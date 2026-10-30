# M09 — Break/fix 01: PDB Blocks Drain

> Pre-req: the baseline tour. You saw a budget with one allowed disruption and the eviction API enforce it. This budget allows none.

A kernel CVE landed, and the worker node needs a patch. The plan is routine: drain the worker so its Pods move, patch it, uncordon it. The drain stalls. The eviction it attempts comes back refused.

The workload in the way is `sip-registrar` in `signaling`. It is healthy at 2/2 Running. Nothing crashes and nothing is `Pending`. The block is the **PodDisruptionBudget** that guards it.

Your job: read why the eviction is refused, find the number that governs it, and give the budget enough headroom for maintenance. Then check what else a drain needs.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
