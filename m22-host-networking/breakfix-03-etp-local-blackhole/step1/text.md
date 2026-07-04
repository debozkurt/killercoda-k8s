# Step 1 — Diagnose the per-node reachability split

The Pod is healthy and the endpoints are populated, so don't chase the workload. The failure is at the NodePort layer — reproduce it per node, then read the policy.

## The Service looks completely normal

```bash
kubectl get svc rtp-ingress -n media
kubectl get endpoints rtp-ingress -n media
```{{exec}}

`80:30080/TCP`, a real ClusterIP, and a populated `ENDPOINTS` list. By M04's reflex the Service has somewhere to send traffic — so this is *not* the empty-EndpointSlice black hole. Confirm the Pod is fine:

```bash
kubectl get pod -n media -l app=rtp-ingress -o wide
```{{exec}}

`Running`, `Ready`, on a single node. Note which node.

## Reproduce the split — hit each node's IP

```bash
for ip in $(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'); do
  echo -n "$ip:30080 -> "; curl -s --max-time 5 -o /dev/null -w '%{http_code}\n' http://$ip:30080 || echo TIMEOUT
done
```{{exec}}

One node returns `200`; the other **times out** (not `refused` — the packet is silently dropped, exactly M04's hang-vs-reject distinction). The node that works is the one running the Pod.

## Read the policy that causes it

```bash
kubectl get svc rtp-ingress -n media \
  -o jsonpath='type={.spec.type}  externalTrafficPolicy={.spec.externalTrafficPolicy}{"\n"}'
```{{exec}}

`externalTrafficPolicy=Local`. Under `Local`, kube-proxy programs each node to serve the NodePort **only if that node has a local endpoint**, and to drop the traffic otherwise — it never forwards across nodes, which is how it preserves the client's source IP. With one replica on one node, every other node is a blackhole. On to the fix.
