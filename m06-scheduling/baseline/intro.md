# M06 — Baseline Tour

Every Pod you've run so far landed on *some* node — and the component that chose, for each one, was the **kube-scheduler**. It watches for Pods with no node assigned, filters the nodes each Pod *can* run on (does it fit? does it tolerate the taints? does it match the affinity?), scores the survivors, and binds the Pod to the best one. When no node survives the filter, the Pod sits `Pending` — and that's most of this module.

This tour runs on the full Polyphone fleet on a **2-node cluster**: one control-plane node (tainted, so ordinary workloads stay off it) and one worker (where the fleet actually runs). Nothing to fix — you're learning to *read* the placement decisions the fleet already embodies before the break/fix scenarios break each one.

Four short steps:

1. **Where the fleet landed** — the two nodes, the control-plane taint, and why the whole fleet is on the worker
2. **Requests, limits, and QoS** — the resource contract on each Pod, and the class that decides who dies first under pressure
3. **Steering placement: affinity and taints** — the nodeAffinity and tolerations the fleet already uses to control where Pods go
4. **The scheduler's decision and headroom** — the `Scheduled` event, and how much room is left before the next Pod won't fit

See what healthy placement looks like, so a `Pending` Pod stands out later. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
