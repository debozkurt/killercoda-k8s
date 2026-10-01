# Step 5 — The Pending triage

A `Pending` Pod has no node, so no container ran and no log exists. The scheduler writes the whole diagnosis into one event. Two commands find it.

## Find Pods without a node

```bash
kubectl get pods -A --field-selector=status.phase=Pending
```{{exec}}

`No resources found`. On a healthy cluster the list is empty. A Pod in this list is waiting for a node, or for storage (M05).

## Find the scheduler's refusals

```bash
kubectl get events -A --field-selector reason=FailedScheduling
```{{exec}}

Also empty. When a Pod cannot be placed, this is where its message appears, and `describe pod` shows the same message in its `Events` block.

## Read the message

A `FailedScheduling` message has one fixed shape. For a Pod that asks for too much memory on this cluster, it reads:

```text
0/2 nodes are available: 1 Insufficient memory, 1 node(s) had untolerated taint
{node-role.kubernetes.io/control-plane: }. preemption: 0/2 nodes are available: ...
```

Read it in three parts:

- `0/2 nodes are available` — no node survived the filters.
- Each `N reason` entry — N nodes stopped at that filter. Each node reports only its first failure. The scheduler sorts the entries alphabetically, not by node.
- `preemption:` — whether evicting a lower-priority Pod would help. Stop reading before it.

The scheduler can evaluate Nodes concurrently. For each Node, it calls Filter plugins in the scheduler profile's configured order. The first rejection stops filtering for that Node. The order is configurable, so use this table as a map from event text to the failed constraint, not as a universal execution sequence:

```text
failed constraint         typical event text
-----------------------   -------------------------------------------------
taints and tolerations    node(s) had untolerated taint {key: value}
node affinity, selector   node(s) didn't match Pod's node affinity/selector
requests vs Allocatable   Insufficient cpu | Insufficient memory
spread, anti-affinity     node(s) didn't match pod anti-affinity rules
                          node(s) didn't match pod topology spread constraints
```

That table is the `Pending` differential. Here, the control-plane entry always appears, because that node fails the first filter. Skip it and read the worker's entry.

Each break/fix scenario lands on one branch of this table, and one flips to the runtime side. See `finish.md` for the order.
