# M06 — Break/fix 03: Anti-affinity Unschedulable

> Pre-req: breakfix-01 and 02. You read `FailedScheduling` for a resource shortfall and for a taint. This is a third reason a Pod does not get a node.

A signaling workload, `sip-director`, runs 3 replicas so that one node failure never takes out the whole service. It is running short: `kubectl get deploy` shows `1/3` ready, and two of its Pods are `Pending`. No node is out of memory and no taint blocks the workload. The one running replica proves the workload itself can schedule.

The cause is a placement rule the workload imposes on itself: no two replicas may share a node. That is the availability property you want, until the cluster has too few nodes to honor it.

Your job: read why the extra replicas do not schedule, and give the workload a rule the cluster can satisfy. The fix has a second trap in it. Read the rollout's state after you change the rule.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
