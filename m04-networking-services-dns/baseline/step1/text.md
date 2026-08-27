# Step 1 — Pods reach each other without a Service

Every Pod has its own IP. Pod-to-Pod traffic needs no Service, no DNS name, and no ClusterIP.

## Read the Pod addresses

```bash
kubectl get pods -n media -o wide
```{{exec}}

The `IP` column carries one address per Pod and `NODE` says which node holds it. Every container inside a Pod shares that one IP.

## Call one Pod directly from another

The fleet's nginx Pods don't originate calls, so bring your own client. `kubectl run --rm` creates a Pod, runs one command, and deletes it:

```bash
POD_IP=$(kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].status.podIP}')
kubectl run probe --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- -T3 "http://$POD_IP/" | head -4
```{{exec}}

nginx's welcome HTML comes back. The CNI carried that packet. No Service took part.

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
