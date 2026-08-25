# Step 5 — Who owns the EndpointSlice

Step 2 read the EndpointSlice. This step proves you don't own it.

## Watch the list follow the Pods

```bash
kubectl get endpointslice -n media \
  -l kubernetes.io/service-name=session-broker \
  -o custom-columns=NAME:.metadata.name,ENDPOINTS:.endpoints[*].addresses
```{{exec}}

One address — `session-broker` runs a single replica. Add a second:

```bash
kubectl scale deploy/session-broker -n media --replicas=2
kubectl rollout status deploy/session-broker -n media --timeout=60s
kubectl get endpointslice -n media \
  -l kubernetes.io/service-name=session-broker \
  -o custom-columns=NAME:.metadata.name,ENDPOINTS:.endpoints[*].addresses
```{{exec}}

Two addresses now. Nobody edited the Service, and nobody edited the slice.

## Delete it and watch it come back

```bash
SLICE=$(kubectl get endpointslice -n media \
  -l kubernetes.io/service-name=session-broker -o name | head -1)
kubectl delete "$SLICE" -n media
sleep 3
kubectl get endpointslice -n media \
  -l kubernetes.io/service-name=session-broker \
  -o custom-columns=NAME:.metadata.name,ENDPOINTS:.endpoints[*].addresses
```{{exec}}

It's back, usually under a new name. The **EndpointSlice controller** rebuilt it from the Service's selector and the `Ready` Pods — the same reason hand-editing an address never sticks.

## Put it back

```bash
kubectl scale deploy/session-broker -n media --replicas=1
kubectl rollout status deploy/session-broker -n media --timeout=60s
```{{exec}}

The list is **derived state**. To change it, change one of its two inputs: the selector, or Pod readiness. That is exactly why an empty EndpointSlice has only those two causes — the second break/fix scenario is one of them.
