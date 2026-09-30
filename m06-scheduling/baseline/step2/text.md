# Step 2 — Requests, limits, and QoS

Each container can declare two numbers per resource, and a different component reads each one. The docs put it this way: "When you specify the resource *request* for containers in a Pod, the kube-scheduler uses this information to decide which node to place the Pod on. When you specify a resource *limit* for a container, the kubelet enforces those limits."

## Read a Pod's requests and limits

```bash
kubectl describe pod -n media -l app=session-broker
```{{exec}}

In the container block, find `Limits:` and `Requests:`. They read cpu 100m and memory 64Mi for the limits, and cpu 25m and memory 32Mi for the requests. Near the bottom, the `QoS Class:` line reads `Burstable`.

## The QoS class follows from those numbers

Kubernetes derives a **QoS class** from requests and limits when it creates the Pod:

- **Guaranteed** — every container sets CPU and memory requests and limits, and each limit equals its request
- **Burstable** — not Guaranteed, and at least one request or limit is set
- **BestEffort** — no container sets any request or limit

Survey the whole fleet in one listing. This is one of the few places where `custom-columns` earns its keep, because the field sits in every Pod's `status`:

```bash
kubectl get pods -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,QOS:.status.qosClass
```{{exec}}

Every fleet Pod reads `Burstable`: each sets requests below its limits. QoS estimates which Pods suffer first under node pressure. The kubelet's real ranking starts with Pods that use more than they request, so `BestEffort` Pods, which request nothing, always qualify.

## A request is a reservation, not live usage

The node keeps a ledger of the requests it has accepted. The `describe node` output is several screens long, so filter to the ledger:

```bash
kubectl describe node -l '!node-role.kubernetes.io/control-plane' | grep -A8 'Allocated resources'
```{{exec}}

The table lists the total CPU and memory requests as a percentage of the node's Allocatable. Now read what the node actually uses (metrics-server needs about a minute after boot):

```bash
kubectl top nodes
```{{exec}}

Live usage sits well below the reserved total. The scheduler reads only the reserved total. A node can refuse a new Pod while its CPU is nearly idle, because its requests are already booked.

Next: how the fleet steers which node a Pod lands on.
