# Step 1 — Pods reach each other without a Service

Every Pod has its own IP. Pod-to-Pod traffic needs no Service, no DNS name, and no ClusterIP.

## Read the Pod addresses

```bash
kubectl get pods -n media -o wide \
  -o custom-columns=NAME:.metadata.name,IP:.status.podIP,NODE:.spec.nodeName
```{{exec}}

Each Pod carries one IP. Every container inside a Pod shares it.

## Call one Pod directly from another

```bash
POD_IP=$(kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].status.podIP}')
kubectl run probe --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- -T3 "http://$POD_IP/" | grep -o '<title>.*</title>'
```{{exec}}

nginx answers. The CNI carried that packet. No Service took part.

## Then why does a Service exist?

Because the address does not last. Delete the Pod and read the new one:

```bash
echo "was: $POD_IP"
kubectl delete pod -n media -l app=session-broker
kubectl wait --for=condition=Ready pod -n media -l app=session-broker --timeout=90s
kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].status.podIP}'; echo " <- now"
```{{exec}}

A different address, for the same workload. Nothing outside the Pod can hold a Pod IP as configuration.

**Pod IP** is a current network location. A **Service** is a stable identity plus a backend set. The rest of this tour builds the second on top of the first.
