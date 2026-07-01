# M06 — Break/fix 02: Untolerated Taint

> Pre-req: breakfix-01. You've read a `FailedScheduling` event for a resource shortfall; this one is `Pending` for a different reason.

The platform team dedicated the worker node to a telephony workload class and tainted it to keep everything else off. A new edge workload, `pstn-probe`, was then deployed to the `edge` namespace — and its Pod is stuck `Pending`. This time no node is short on CPU or memory; the node is actively *refusing* the Pod.

The rest of the fleet is untouched and running, which is itself a clue about what kind of taint this is. Your job: read the `FailedScheduling` event, find the taint on the node, and give the Pod the toleration it needs to land — the same toleration mechanism `sbc-edge` already uses to reach the control-plane node.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
