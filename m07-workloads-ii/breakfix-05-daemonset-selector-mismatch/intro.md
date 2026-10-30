# M07 — Break/fix 05: DaemonSet Selector Mismatch

> Pre-req: breakfix-03. There, a DaemonSet covered too few nodes because of a taint. Here, the cause is a selector.

The platform team rolled out `disk-exporter` to the `media` namespace. It is a node-local agent that exports disk metrics from the fast-disk nodes. The pipeline reported that the DaemonSet rolled out. The dashboards stay empty, and no `disk-exporter` Pod exists anywhere.

Nothing is `Pending`, and no event points at trouble. The worker runs other media workloads that need fast disks, and they are healthy.

Your job: find out why the controller created no Pod, and fix the side that is wrong.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
