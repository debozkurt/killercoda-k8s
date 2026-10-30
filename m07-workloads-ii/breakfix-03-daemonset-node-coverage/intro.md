# M07 — Break/fix 03: DaemonSet Node Coverage

> Pre-req: breakfix-01 and 02. This scenario moves from StatefulSets to the other controller, the DaemonSet.

The team added a per-node RTP media-quality probe, `rtp-probe`, to the `edge` namespace as a DaemonSet. Like `sbc-edge`, it must run on **every** node. A node without it is a node whose media quality goes unmeasured. The rollout finished without error, and its one Pod is `Running` and Ready.

One Pod is the problem. This cluster has two nodes, and a DaemonSet that covers every node should have two Pods. Nothing is `Pending`, nothing crashed, and no event points at trouble. One node has no `rtp-probe` Pod, and nothing reports it.

Your job: find the uncovered node, find out why the DaemonSet never placed a Pod there, and restore full coverage. `sbc-edge`, in the same namespace, reaches both nodes.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
