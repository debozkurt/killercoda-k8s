# Step 4 — Place a Pod and read the ledger

The scheduler keeps no private state about what it booked. It reads the requests of the Pods on each node. Create one Pod, and watch it land and reserve room.

## Read the ledger before

```bash
kubectl describe node -l '!node-role.kubernetes.io/control-plane' | grep -A8 'Allocated resources'
```{{exec}}

Note the `cpu` and `memory` values in the `Requests` column.

## Create a Guaranteed Pod

This Pod sets each limit equal to its request, which makes it `Guaranteed`. It uses `nginx:1.25` because the node already holds that image:

```bash
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata: { name: placement-demo, namespace: analytics }
spec:
  containers:
    - name: app
      image: nginx:1.25
      resources:
        requests: { cpu: 20m, memory: 64Mi }
        limits:   { cpu: 20m, memory: 64Mi }
YAML
kubectl wait --for=condition=Ready pod placement-demo -n analytics --timeout=60s
kubectl describe pod placement-demo -n analytics
```{{exec}}

Read three lines:

- `Node:` names the worker.
- `QoS Class:` reads `Guaranteed`.
- The last event reads `Scheduled`, from `default-scheduler`, with the message `Successfully assigned analytics/placement-demo to` the worker.

That event is the scheduler's record of a filter, a score and a bind. For a Pod it cannot place, the same slot holds `FailedScheduling` instead.

Off the happy path: if the Pod stays `Pending`, the worker's requests are already full. The `Events` block then names `Insufficient cpu` or `Insufficient memory`. Delete the Pod and continue.

## Read the ledger after

```bash
kubectl describe node -l '!node-role.kubernetes.io/control-plane' | grep -A8 'Allocated resources'
```{{exec}}

The CPU requests grew by 20m and the memory requests by 64Mi. The Pod uses almost none of it, and the reservation holds anyway.

## Release the reservation

```bash
kubectl delete pod placement-demo -n analytics
kubectl describe node -l '!node-role.kubernetes.io/control-plane' | grep -A8 'Allocated resources'
```{{exec}}

The totals drop back. Deleting a Pod frees its requests for the next Pod the scheduler places.

Next: what to run when a Pod does not get a node.
