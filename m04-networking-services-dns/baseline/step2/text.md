# Step 2 — The Pod's own view of the network

Step 1 read Pod IPs from the outside, with `kubectl`. Now look from the inside, where the **network namespace** is what you're actually seeing.

## The interface and the route

```bash
kubectl run probe --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  sh -c 'ip addr show eth0; ip route'
```{{exec}}

One interface, `eth0`, carrying the Pod IP `kubectl get -o wide` reported — and a default route pointing at the node. That is the whole of a Pod's network view: its own interface, its own routing table, nothing of the node's or any other Pod's.

## Two containers, one namespace

`call-recorder` is the fleet's only multi-container Pod: a `recorder` serving on 8080 and an `uploader` beside it. Ask each container what its address is:

```bash
POD=$(kubectl get pod -n media -l app=call-recorder -o jsonpath='{.items[0].metadata.name}')
kubectl exec "$POD" -n media -c recorder -- ip addr show eth0
kubectl exec "$POD" -n media -c uploader -- ip addr show eth0
```{{exec}}

The same `inet` line both times. Two containers, one `eth0`, one IP — they are in the same network namespace, so there is only one interface to see. This is why a Pod, not a container, is what gets an address.

The consequence is reachability with no network in between:

```bash
kubectl exec "$POD" -n media -c uploader -- wget -qO- localhost:8080
```{{exec}}

`recorder-ok` comes back. The `uploader` reached the `recorder` on `localhost` — no Service, no Pod IP, no DNS. That is the standard sidecar contract, and the reason two containers in one Pod can never both bind the same port.

## Which plugin is doing this

The interface, the IP, and the route were all installed by the CNI plugin when the Pod started. Its configuration sits on the node:

```bash
ls /etc/cni/net.d/
```{{exec}}

The file name identifies the plugin this cluster runs. Worth knowing before an incident: the Kubernetes objects are identical across plugins, but the tooling for reading the datapath is not.

Next: what the fleet puts in front of these addresses, and why.
