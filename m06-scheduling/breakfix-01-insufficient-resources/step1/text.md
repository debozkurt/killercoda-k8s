# Step 1 — Diagnose the Pending Pod

A `Pending` Pod has no logs — it never ran. The story lives in one scheduler event.

## Confirm it's Pending

```bash
kubectl get pods -n analytics -o wide
```{{exec}}

`stream-analyzer-...` is `Pending` with no `NODE` assigned. It's not crashing, not pulling — it was never placed.

## Read why the scheduler refused it

```bash
kubectl describe pod -n analytics -l app=stream-analyzer | grep -A6 Events
```{{exec}}

The `FailedScheduling` event names the reason per node, something like:

```text
0/2 nodes are available: 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: },
                         1 Insufficient memory.
```

Skip the control-plane line — that taint is expected on this cluster (baseline). The actionable half is the worker's line: **`Insufficient memory`**. The scheduler fits Pods by their memory *request*, and no node has enough free to cover this one's.

## How much is it asking for?

```bash
kubectl get pod -n analytics -l app=stream-analyzer \
  -o jsonpath='{.items[0].spec.containers[0].resources.requests}'; echo
```{{exec}}

`memory:256Gi`. Now compare against what a node actually offers:

```bash
kubectl get nodes -o custom-columns='NODE:.metadata.name,ALLOCATABLE_MEM:.status.allocatable.memory'
```{{exec}}

The nodes have a couple of GiB each — `256Gi` fits nowhere. That's a classic unit slip: someone meant `256Mi` and typed `256Gi`. The image and app are fine; the *request* is impossible. On to the fix.
