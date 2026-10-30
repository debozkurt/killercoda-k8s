# M07 — Baseline Tour

A Deployment treats its Pods as interchangeable. Each Pod has a random name, and any replica serves any request. Two kinds of workload need more than that, and the fleet runs both.

A **StatefulSet** gives each Pod an identity that survives restarts: a fixed ordinal name such as `media-engine-0`, a DNS name that peers can address, and a PersistentVolumeClaim (a request for disk, also called a claim) that stays with that ordinal. The fleet runs four: `media-engine`, `reg-proxy`, `presence` and `pstn-gateway`.

A **DaemonSet** runs one Pod on every eligible node. You set no replica count. The node list sets the Pod count. `sbc-edge` is the fleet's DaemonSet, because a Session Border Controller must run on every node that terminates media.

The tour runs on the full Polyphone fleet on a **2-node cluster**. One control-plane node carries a taint that keeps ordinary workloads off it. One worker runs the fleet. Nothing is broken. You read what each guarantee looks like while it holds, so that a broken one stands out later.

Five short steps:

1. **Two controllers a Deployment cannot replace** — find the StatefulSets and the DaemonSet, and read their Pod names
2. **StatefulSet identity** — the headless Service and the per-Pod DNS name
3. **StatefulSet storage** — the claim that follows each ordinal
4. **Delete a Pod, keep the identity** — prove that the name, the claim and the data return
5. **DaemonSet coverage** — one Pod per eligible node, and the toleration that reaches the control-plane node

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
