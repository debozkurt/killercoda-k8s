# Step 2 — Requests, limits, and QoS

Every fleet container declares two numbers per resource. The **request** is what the scheduler fits; the **limit** is the runtime ceiling. From those two, Kubernetes derives a **QoS class**.

## Read a Pod's requests and limits

```bash
kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{range .items[0].spec.containers[0]}{.name}{": requests="}{.resources.requests}{" limits="}{.resources.limits}{"\n"}{end}'
```{{exec}}

`requests={cpu:25m, memory:32Mi}  limits={cpu:100m, memory:64Mi}`. The scheduler only ever sums the **requests** and checks them against a node's free space — limits don't affect placement at all.

## The QoS class falls out of those numbers

```bash
kubectl get pods -A -o custom-columns=\
'NS:.metadata.namespace,NAME:.metadata.name,QOS:.status.qosClass' | grep -v kube-system | head -20
```{{exec}}

The fleet is **Burstable** — every Pod sets requests *and* limits, but the requests are below the limits (not equal). The three classes: **Guaranteed** (request == limit on every container), **Burstable** (something set, not equal), **BestEffort** (nothing set). Under memory pressure the kubelet evicts BestEffort first, then Burstable, then Guaranteed — so QoS is the kill order.

## Requests are a reservation, not live usage

`describe node` shows what's *reserved* on the worker — the sum of requests, not what's actually being used:

```bash
kubectl describe node -l '!node-role.kubernetes.io/control-plane' | grep -A6 'Allocated resources'
```{{exec}}

Compare that to real-time usage (metrics-server is installed; give it a few seconds after boot):

```bash
kubectl top nodes
```{{exec}}

The worker's *requested* CPU/memory (from `describe`) is what the scheduler treats as "taken"; `top` shows the fleet barely uses it. A Pod fits based on the reservation, not the live number — which is exactly why a Pod that requests far more than it needs can wedge a node that has plenty of free memory. Next: how the fleet steers *which* node it lands on.
