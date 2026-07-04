# Step 2 — hostPort: one port onto the node

`sip-edge` doesn't take the whole node network — it keeps its normal pod IP and maps just *one* port. `hostPort: 5060` tells the CNI's `portmap` plugin to wire the node's `:5060` straight through to this container's `:80`. That's how you publish a single SIP port on the node without going all-in on `hostNetwork`.

## It keeps a normal pod IP

```bash
kubectl get pod -n edge -l app=sip-edge -o wide
```{{exec}}

The `IP` is a pod-network address (not the node IP) — the contrast with `rtp-relay`. Now read the port mapping:

```bash
kubectl get pod -n edge -l app=sip-edge \
  -o jsonpath='{.items[0].spec.containers[0].ports[0]}{"\n"}'
```{{exec}}

`containerPort: 80` with `hostPort: 5060` — the node's 5060 forwards to the container's 80.

## Reach the container on the node's port

```bash
NODE_IP=$(kubectl get pod -n edge -l app=sip-edge -o jsonpath='{.items[0].status.hostIP}')
curl -s --max-time 5 http://$NODE_IP:5060 | head -1
```{{exec}}

nginx answers on the node's `:5060`, mapped down to its `:80`. The port is a real resource on the node now: only one Pod per node can hold `hostPort: 5060`. A second Pod asking for the same host port won't schedule — it sits `Pending` with a `didn't have free ports` event (the same node-resource logic as CPU/memory from M06).
