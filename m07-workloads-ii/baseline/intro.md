# M07 — Baseline Tour

Most of the fleet runs as **Deployments** — interchangeable Pods with random names, any replica as good as the next. But some workloads can't be interchangeable, and for those the fleet uses two other controllers.

A **StatefulSet** gives each Pod a stable identity: a fixed ordinal name (`reg-proxy-0`, `reg-proxy-1`), a per-Pod DNS record so peers can address a specific member, and its own PersistentVolumeClaim that stays with that ordinal across restarts. The fleet runs four: `media-engine`, `reg-proxy`, `presence`, and `pstn-gateway` — the stateful tier where each member owns its data. A **DaemonSet** runs exactly one Pod on every eligible node; `sbc-edge` is one, because a Session Border Controller has to be present wherever media terminates.

This tour runs on the full Polyphone fleet on a **2-node cluster** (one tainted control-plane, one worker). Nothing is broken — you're learning to *read* the guarantees these controllers make before the break/fix scenarios break each one.

Four short steps:

1. **Two controllers a Deployment can't replace** — spot the StatefulSets and the DaemonSet in the fleet, and what makes each different
2. **StatefulSet identity** — ordinal names and the headless Service that gives each Pod a stable DNS record
3. **StatefulSet storage** — the sticky `state-<sts>-<ordinal>` PVCs that follow each ordinal
4. **DaemonSet** — one Pod per node, and the toleration that lets `sbc-edge` reach the tainted control-plane

See what each guarantee looks like when it holds, so a broken one stands out later. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
