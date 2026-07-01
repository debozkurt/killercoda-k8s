# M07 — Break/fix 03: DaemonSet Node Coverage

> Pre-req: breakfix-01 and 02 (StatefulSets). This scenario switches to the other controller — the DaemonSet.

A per-node RTP media-quality probe, `rtp-probe`, was added to the `edge` namespace as a DaemonSet. Like `sbc-edge`, it's supposed to run on **every** node — a node without it is a node whose media quality goes unmeasured. It rolled out without error: its one Pod is `Running` and Ready.

That "one Pod" is the problem. This is a 2-node cluster, and a DaemonSet that covers every node should have two. Nothing is `Pending`, nothing crashed, no event points at trouble — the second node just quietly has no `rtp-probe` on it. Your job: confirm which node is uncovered, work out why the DaemonSet never placed a Pod there, and restore full coverage.

The contrast is right next to it: `sbc-edge` is a DaemonSet in the same namespace that *does* reach both nodes. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
