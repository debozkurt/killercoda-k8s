# M14 — Baseline Tour

M04 got traffic flowing and left the network flat: by default, any pod can reach any other pod, in any namespace. M14 is about the two controls that shape that traffic. **NetworkPolicy** segments the east-west, pod-to-pod path — a whitelist that switches a pod to default-deny the moment it selects it. **Ingress** is the north-south, L7 front door — an HTTP router that a controller turns into real proxying.

This tour runs on the full Polyphone fleet, plus two additions the setup applies for you: a healthy NetworkPolicy set in the `media` namespace (a default-deny for ingress, and one allow that lets the `app-services` plane reach `session-broker`), and the ingress-nginx controller fronting an Ingress that routes to `portal-ui`. Traffic is driven from throwaway in-cluster clients (`busybox` Pods you create with `kubectl run --rm`), since the fleet's own nginx Pods don't originate calls.

Four short steps:

1. **The default-allow to default-deny flip** — the two policies in `media`, and how selecting a pod changes its default
2. **Enforcement, proven both ways** — an allowed source gets through; a denied one hangs to a timeout (the policy-drop signature)
3. **Cross-namespace peer selection** — how the allow reaches across namespaces, and why namespaces must be labeled
4. **The Ingress front door** — the controller, the IngressClass, and an external HTTP request routed to a Service

Nothing to fix here. See what shaped, working traffic looks like before the break/fix scenarios snap each control. The cluster plus the ingress controller take about 2–4 minutes to come up. Click **Start** when ready.
