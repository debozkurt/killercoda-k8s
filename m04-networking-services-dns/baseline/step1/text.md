# Step 1 — Pods reach each other without a Service

Every Pod has its own IP. Pod-to-Pod traffic needs no Service, no DNS name, and no ClusterIP.

## Read the Pod addresses

```bash
kubectl get pods -n media -o wide
```{{exec}}

The `IP` column carries one address per Pod and `NODE` says which node holds it. Every container inside a Pod shares that one IP.

Those addresses come from the **CNI plugin** (Container Network Interface), the node component that attaches each Pod to the network. The kubelet calls it when a Pod starts; it wires the Pod's network namespace to the node and hands back the IP. It also carries Pod-to-Pod traffic between nodes. Kubernetes requires that every Pod reach every other Pod at its own IP, on any node, with **neither address translated** — so a server sees the client's real Pod IP. The CNI plugin is what delivers that guarantee, and it's a per-cluster choice (Cilium, Calico, and others), not one fixed implementation.

It runs as a DaemonSet, one Pod per node, since every node needs its own copy:

```bash
kubectl get daemonset -n kube-system
```{{exec}}

The network plugin is the DaemonSet whose `DESIRED` count equals your node count. Knowing which one your cluster runs matters the moment you need its logs or its own CLI — the Kubernetes objects stay identical across implementations, but the debugging tools don't.

## Call one Pod directly from another

The fleet's nginx Pods don't originate calls, so bring your own client. `kubectl run --rm` creates a Pod, runs one command, and deletes it:

```bash
POD_IP=$(kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].status.podIP}')
kubectl run probe --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- -T3 "http://$POD_IP/" | head -4
```{{exec}}

nginx's welcome HTML comes back. The CNI plugin carried that packet. No Service took part.

## Then why does a Service exist?

Because the address does not last. Note `session-broker`'s IP from the listing above, then replace the Pod:

```bash
kubectl delete pod -n media -l app=session-broker
```{{exec}}

The Deployment starts a replacement immediately. Read the addresses again:

```bash
kubectl get pods -n media -o wide
```{{exec}}

Same workload, different address. Nothing outside the Pod can hold a Pod IP as configuration.

A **Pod IP** is a current network location. A **Service** is a stable identity plus a backend set. The rest of this tour builds the second on top of the first.
