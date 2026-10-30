# Step 5 — Graceful shutdown, and the delete that skips the budget

A rollout, a drain, and a scale-down all terminate Pods. Whether that drops calls depends on how each Pod shuts down.

## Read the grace period

```bash
POD=$(kubectl get pods -n call-routing -l app=route-engine -o name | head -1)
kubectl get $POD -n call-routing -o yaml | grep terminationGracePeriodSeconds
```{{exec}}

It reads 30, the default. The kubelet waits that long after it asks the container to stop. The clock starts when the delete arrives.

## What happens on delete

Two paths start at once:

1. The control plane begins removing the Pod from its Service endpoints, so new traffic stops. This is asynchronous, and requests can still arrive for a moment.
2. The kubelet runs the `preStop` hook (if the Pod has one), sends SIGTERM to the container, and waits. If the process is still alive when the grace period ends, the kubelet sends SIGKILL.

A well-behaved app catches SIGTERM, finishes in-flight requests, and exits before the budget runs out. Delete one Pod and watch the Deployment replace it:

```bash
kubectl delete $POD -n call-routing
kubectl get pods -n call-routing -l app=route-engine
```{{exec}}

`kubectl delete` waits until the Pod is gone, which here takes about a second because nginx exits on SIGTERM. The listing shows the replacement. The other replica kept serving.

## Delete skips the budget

The PDB from step 4 guards the eviction API. `kubectl delete` does not call it. Delete both replicas with one selector:

```bash
kubectl delete pods -n call-routing -l app=route-engine --wait=false
kubectl get pods -n call-routing -l app=route-engine
```{{exec}}

Both Pods go `Terminating` in the same second, and two new Pods start. The budget said 1 disruption at a time, and nothing enforced it. For a few seconds no replica is Ready. Use eviction (`kubectl drain`) for planned work, and `kubectl delete` only when you accept the gap.

Rolling updates, budgets, and graceful shutdown compose: a rollout terminates Pods in batches, a PDB paces a drain, and shutdown makes each exit clean. Read [`LESSON.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m09-resilience-autoscaling/LESSON.md) for the why, then break each piece. See `finish.md`.
