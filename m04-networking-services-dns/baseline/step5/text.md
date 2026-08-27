# Step 5 — Who owns the EndpointSlice

Step 4 read the EndpointSlice. This step proves you do not own it.

## Watch the list follow the Pods

```bash
kubectl get endpointslice -n media -l kubernetes.io/service-name=session-broker
```{{exec}}

One address — `session-broker` runs a single replica. Add a second:

```bash
kubectl scale deploy/session-broker -n media --replicas=2
kubectl rollout status deploy/session-broker -n media --timeout=60s
kubectl get endpointslice -n media -l kubernetes.io/service-name=session-broker
```{{exec}}

Two addresses in `ENDPOINTS` now. Nobody edited the Service, and nobody edited the slice.

## Delete it and watch it come back

```bash
kubectl delete endpointslice -n media -l kubernetes.io/service-name=session-broker
sleep 5
kubectl get endpointslice -n media -l kubernetes.io/service-name=session-broker
```{{exec}}

It's back, under a new name, with the same addresses. The **EndpointSlice controller** rebuilt it from the Service's selector and the `Ready` Pods — the same reason hand-editing an address never sticks.

The `sleep` is the point, not a workaround: reconciliation is a loop, not a transaction. Read a controller's output too fast and you see the gap rather than the result. If the listing is still empty, run the `get` again — or watch it happen with `kubectl get endpointslice -n media -w` and Ctrl-C when the new slice appears.

## Put it back

```bash
kubectl scale deploy/session-broker -n media --replicas=1
kubectl rollout status deploy/session-broker -n media --timeout=60s
```{{exec}}

The list is **derived state**. To change it, change one of its two inputs: the selector, or Pod readiness. That is exactly why an empty EndpointSlice has only those two causes.
