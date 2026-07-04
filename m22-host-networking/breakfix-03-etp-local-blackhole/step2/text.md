# Step 2 — Fix it and verify

There are two honest fixes, and which one is right depends on whether you need the client's source IP. The lab fix restores reachability everywhere; the production note covers keeping `Local`.

## Restore reachability: switch to Cluster

```bash
kubectl patch svc rtp-ingress -n media --type=merge \
  -p '{"spec":{"externalTrafficPolicy":"Cluster"}}'
```{{exec}}

Under `externalTrafficPolicy: Cluster`, a node that has no local endpoint forwards the traffic to a Pod on another node instead of dropping it — so the NodePort answers on every node. The trade-off is a source-NAT that replaces the client IP with the node's, and one extra hop. Or by hand:

```bash
kubectl edit svc rtp-ingress -n media
# change  externalTrafficPolicy: Local
# to      externalTrafficPolicy: Cluster
```

## The real-world version

`Local` isn't wrong — it's the right choice when you need the real client IP (source-based routing, rate-limiting, or media that keys off the caller's address). Its requirement is that **every node that receives external traffic has a local endpoint.** So the other fix is to keep `Local` and guarantee that: run the front-end as a **DaemonSet** (one Pod per node), or spread enough replicas with topology spread so no serving node is empty. Reach for `Cluster` when even load-balancing matters more than the source IP; keep `Local` (with an endpoint per node) when the source IP is load-bearing. What you can't do is pair `Local` with a single-node backend and expect every node's IP to work.

## Verify

```bash
kubectl get svc rtp-ingress -n media \
  -o jsonpath='externalTrafficPolicy={.spec.externalTrafficPolicy}{"\n"}'
for ip in $(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'); do
  echo -n "$ip:30080 -> "; curl -s --max-time 5 -o /dev/null -w '%{http_code}\n' http://$ip:30080 || echo TIMEOUT
done
```{{exec}}

Every node's IP now returns `200` — the blackhole is gone. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
