# M06 — Break/fix 02: Untolerated Taint

> Pre-req: breakfix-01. You read a `FailedScheduling` event for a resource shortfall. This Pod is `Pending` for a different reason.

The platform team dedicated the worker node to a telephony workload class, and tainted it to keep everything else off. Then a new edge workload, `pstn-probe`, rolled out to the `edge` namespace. Its Pod is stuck `Pending`. This time no node is short of CPU or memory. The node refuses the Pod.

The rest of the fleet still runs on that worker. That fact is a clue about which taint effect the team used.

Your job: read the `FailedScheduling` event, find the taint on the node, and give the Pod the toleration it needs. `sbc-edge` already uses the same mechanism to reach the control-plane node.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
