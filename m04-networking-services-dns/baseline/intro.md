# M04 — Baseline Tour

Pods are disposable — their IPs change every time a Deployment rolls, a node drains, or an autoscaler kicks in. The **Service** is the abstraction that hides that churn: a stable name and virtual IP in front of a set of Pods that changes underneath it. Every call between Polyphone components rides a Service and a DNS lookup. M00–M03 took that plumbing for granted; M04 is about the plumbing itself, and the three places it silently stops carrying traffic.

This tour runs on the full Polyphone fleet — no new workloads. You'll exercise the Services it already runs, driving traffic from a throwaway in-cluster client (a `busybox` Pod you create with `kubectl run --rm`), since the fleet's own nginx Pods don't originate calls.

Six short steps walk the request path:

1. **Pods reach each other without a Service** — every Pod has an IP, and that IP doesn't last
2. **A Service is a stable identity** — its ClusterIP, and reaching it without ever seeing a Pod IP
3. **Selector to EndpointSlice** — how a Service finds its Pods, and the one command that proves it has any
4. **Who owns the EndpointSlice** — scale it, delete it, watch the controller rebuild it from selector + readiness
5. **port, targetPort, and the listener** — the three port fields, and which one actually matters
6. **Cluster DNS from inside a Pod** — `resolv.conf`, the `<svc>.<ns>` naming scheme, short name vs FQDN, headless

Nothing to fix here. See what a healthy request path looks like before the break/fix scenarios snap each link. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
