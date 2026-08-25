# M04 — Baseline Tour

Pods are disposable — their IPs change every time a Deployment rolls, a node drains, or an autoscaler kicks in. The **Service** is the abstraction that hides that churn: a stable name and virtual IP in front of a set of Pods that changes underneath it. Every call between Polyphone components rides a Service and a DNS lookup. M00–M03 took that plumbing for granted; M04 is about the plumbing itself, and the three places it silently stops carrying traffic.

This tour runs on the full Polyphone fleet — no new workloads. You'll exercise the Services it already runs, driving traffic from a throwaway in-cluster client (a `busybox` Pod you create with `kubectl run --rm`), since the fleet's own nginx Pods don't originate calls.

Seven short steps walk the request path:

1. **A Service is a stable identity** — its ClusterIP, and reaching it without ever seeing a Pod IP
2. **Selector to EndpointSlice** — how a Service finds its Pods, and the one command that proves it has any
3. **port, targetPort, containerPort** — the three port fields, and which one actually matters
4. **Cluster DNS from inside a Pod** — `resolv.conf`, the `<svc>.<ns>` naming scheme, short name vs FQDN
5. **Who owns the EndpointSlice** — scale it, delete it, watch the controller rebuild it from selector + readiness
6. **Three ways to the same backend** — Pod IP, ClusterIP, and DNS name, and what each one proves when it works
7. **The rules behind the ClusterIP** — read kube-proxy's own iptables chains, from the ClusterIP down to the `DNAT`

Nothing to fix here. See what a healthy request path looks like before the break/fix scenarios snap each link. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
