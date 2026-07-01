# M06 — Break/fix 03: Anti-affinity Unschedulable

> Pre-req: breakfix-01 and 02. You've read `FailedScheduling` for a resource shortfall and for a taint; this is a third reason a Pod won't place.

A signaling workload, `sip-director`, was deployed with 3 replicas so a single node failure can never take it all out. But it's running short: `kubectl get deploy` shows `1/3` ready, and two of its Pods are `Pending`. No node is out of memory, and no taint is in the way — the one running replica proves the workload itself schedules fine.

The catch is a *placement rule* the workload imposes on itself: it demands that no two of its replicas share a node. That's exactly the HA property you want — until the cluster doesn't have enough places to honor it. Your job: read why the extra replicas won't schedule, and decide how to give the workload its availability without wedging it.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
