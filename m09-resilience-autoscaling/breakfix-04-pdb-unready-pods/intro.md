# M09 — Break/fix 04: PDB With No Ready Pods

> Pre-req: breakfix-01. There, the budget floor equaled the replica count. Here the floor is sane.

The worker needs a patch, and the drain is stuck again, this time on `trunk-monitor` in `signaling`. Its PodDisruptionBudget asks for 1 of 2 replicas. That is a reasonable floor, and it leaves room for one disruption. The eviction is refused anyway, and `ALLOWED DISRUPTIONS` reads 0.

The budget is not the bug this time. Allowed disruptions is current healthy minus desired healthy, and one of those inputs is wrong.

Your job: find which input is wrong, find why, and repair the cause instead of loosening the budget.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
