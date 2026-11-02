# M14 — Baseline Tour

M04 got traffic flowing and left the network flat. By default, any pod can reach any other pod in any namespace. This module covers the two controls that shape that traffic.

**NetworkPolicy** segments east-west traffic, the pod-to-pod path. A policy that selects a pod makes that pod deny everything the policy does not list. **Ingress** is the north-south front door. It routes outside HTTP to a Service by hostname and path, and a separate controller does the proxying.

The setup applies four additions to the full Polyphone fleet:

- a default-deny for ingress in the media namespace
- one allow that lets the app-services namespace reach session-broker
- the ingress-nginx controller and an Ingress that routes to portal-ui
- probe-demo, a Pod with a readiness probe that starts under the deny

A client for each test is a throwaway busybox Pod that you create with kubectl run --rm. The fleet's own nginx Pods do not originate calls.

Five short steps:

1. **The policies in media** — how selecting a pod isolates it
2. **Enforcement, proven both ways** — one call succeeds, one hangs to a timeout
3. **Cross-namespace peers** — how the allow crosses a namespace boundary
4. **The Ingress front door** — the controller, the class, a route and a 404
5. **Two guarantees** — the node is always allowed, and a second policy adds access

Nothing is broken here. The cluster and the controller take 2–4 minutes to start. Click **Start** when ready.
