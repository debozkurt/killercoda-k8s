# Step 1 — Diagnose the Pending Pod

A `Pending` Pod has no logs, because it never ran. The scheduler wrote its reason into an event.

## Confirm it is Pending

```bash
kubectl get pods -n analytics -o wide
```{{exec}}

`stream-analyzer-...` shows `Pending`, and its `NODE` column reads `<none>`. It is not crashing and not pulling an image. The scheduler never placed it.

## Read why the scheduler refused it

```bash
kubectl describe pod -n analytics -l app=stream-analyzer
```{{exec}}

Two parts of the output matter. In the container block, `Requests:` shows memory 256Gi. At the bottom, the `FailedScheduling` event reads:

```text
0/2 nodes are available: 1 Insufficient memory, 1 node(s) had untolerated taint
{node-role.kubernetes.io/control-plane: }. preemption: 0/2 nodes are available: ...
```

Skip the control-plane entry, which the baseline showed on every refusal. The worker's entry is **`Insufficient memory`**. The scheduler fits a Pod by its requests, and no node has enough free memory to cover this one.

## Compare the request with what a node offers

The `Allocatable:` block is the part of each node that Pods may reserve:

```bash
kubectl describe nodes | grep -A6 Allocatable
```{{exec}}

Read the `memory:` line for each node. Each shows a few GiB at most, written in Ki. A 256Gi request fits nowhere, so no amount of waiting helps. The value is a unit slip: someone meant 256Mi and typed 256Gi.

Next: correct the request.
