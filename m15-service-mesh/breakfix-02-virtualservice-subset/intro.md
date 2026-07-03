# M15 — Break/fix 02: VirtualService Subset

> Pre-req: the M15 baseline tour and break/fix 01. Last time the pod wasn't in the mesh. This time it fully is — and the route still fails.

`session-broker` is returning `503` to its callers again, but the shape is different. Every `media` pod is `2/2`, `session-broker` shows up in `istioctl proxy-status` with `SYNCED` config, its Service has endpoints, and mTLS is healthy. Nothing about the workload is wrong.

The break is in the routing. A **VirtualService** decides which *subset* of a host's pods a request goes to, and a **DestinationRule** defines what those subsets are. Someone pointed the `session-broker` route at a subset that selects pods nobody has deployed — a canary that was never rolled out. istiod dutifully builds an Envoy cluster for that subset, but it has zero endpoints, so the caller's Envoy has no healthy upstream and answers `503`.

This is the failure you debug with `istioctl proxy-config`, not `kubectl get pods` — because the pods are fine. Your job: read the compiled Envoy config to see the route landing on an empty cluster, then point the route back at a subset that has pods. The cluster takes 3–5 minutes to come up. Click **Start** when ready.
