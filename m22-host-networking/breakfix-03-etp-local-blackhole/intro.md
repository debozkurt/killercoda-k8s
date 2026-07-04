# M22 — Break/fix 03: NodePort Blackholes on One Node

> Pre-req: the M22 baseline tour (NodePort, `externalTrafficPolicy`), and M04's EndpointSlice reflex.

External health checks against `rtp-ingress` are flapping: some succeed, some time out, with no pattern in the app itself. The Service is a NodePort on `30080`, the backing Pod is `Running` and `Ready`, `kubectl get svc` looks normal, and `get endpoints` is fully populated. Yet reachability depends on **which node's IP** the client happens to hit.

This is the classic `externalTrafficPolicy: Local` trap. `Local` preserves the client's source IP — which real-time media often needs — by refusing to forward across nodes: a node serves the NodePort only if it has a *local* endpoint, and silently drops the traffic otherwise. With the Pod on a single node, every other node's IP is a blackhole. Nothing is unhealthy; the traffic just has nowhere to go on those nodes.

Your job: reproduce the split by hitting the NodePort on each node's IP, connect it to the policy and where the endpoints actually are, and restore reachability. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
