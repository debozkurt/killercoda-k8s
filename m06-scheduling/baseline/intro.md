# M06 — Baseline Tour

Every Pod you have run so far landed on a node. The **kube-scheduler** chose each node. In the docs' words, it "selects an optimal node to run newly created or not yet scheduled (unscheduled) pods". For each Pod it filters out the nodes the Pod cannot use, scores the rest, and binds the Pod to the best one. When no node survives the filter, the Pod sits `Pending`. Most of this module is about reading why.

The tour runs on the full Polyphone fleet on a **2-node cluster**. One control-plane node carries a taint that keeps ordinary workloads off it. One worker runs the fleet. Nothing is broken here. You read the placement decisions the fleet already carries, so that a broken one stands out later.

Five short steps:

1. **Where the fleet landed** — the two nodes, the control-plane taint, and why the fleet sits on the worker
2. **Requests, limits, and QoS** — the resource contract on each Pod, and the class Kubernetes derives from it
3. **Labels, affinity, and tolerations** — the node affinity and tolerations the fleet uses to control placement
4. **Place a Pod and read the ledger** — create a Pod, watch the scheduler bind it, and watch its request reserve room on the node
5. **The Pending triage** — the commands that split every `Pending` Pod by cause

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
