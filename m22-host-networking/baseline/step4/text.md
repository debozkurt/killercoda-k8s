# Step 4 — externalTrafficPolicy on a NodePort

`rtp-ingress` is a **NodePort** Service: it opens a fixed port (`30080`) on *every* node, so external clients can reach the Pods without a cloud load balancer. Whether every node actually serves that traffic depends on one field — `externalTrafficPolicy`.

## The NodePort and its policy

```bash
kubectl get svc rtp-ingress -n media
kubectl get svc rtp-ingress -n media \
  -o jsonpath='externalTrafficPolicy={.spec.externalTrafficPolicy}{"\n"}'
```{{exec}}

`PORT(S)` shows `80:30080/TCP`, and the policy is `Cluster` — the default. The one backing Pod runs on a single node:

```bash
kubectl get pod -n media -l app=rtp-ingress -o wide
```{{exec}}

## Reachable from every node's IP

Hit the NodePort on *each* node's IP — including the node that isn't running the Pod:

```bash
for ip in $(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'); do
  echo -n "$ip:30080 -> "; curl -s --max-time 5 -o /dev/null -w '%{http_code}\n' http://$ip:30080
done
```{{exec}}

Both nodes return `200`. Under `externalTrafficPolicy: Cluster`, a node that receives the packet but has no local endpoint forwards it on to a Pod elsewhere — reachable everywhere, at the cost of an extra hop and a source-NAT that hides the client's real IP.

The alternative, `Local`, keeps the client IP but only serves nodes that have a local endpoint. On this single-endpoint Service that would blackhole one node — which is breakfix-03.
