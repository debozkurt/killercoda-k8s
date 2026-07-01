# Step 4 — The scheduler's decision and headroom

Scheduling leaves a record. Every placed Pod has a `Scheduled` event, and every node has a headroom figure that predicts what will fit next.

## The Scheduled event

```bash
kubectl describe pod -n media -l app=session-broker | grep -A4 Events
```{{exec}}

You'll see `Scheduled   default-scheduler   Successfully assigned media/session-broker-... to <worker>`. That one line is the scheduler saying "I filtered, I scored, I bound it here." When scheduling *fails*, the same slot instead reads `FailedScheduling` with the per-node reasons — that's the event you'll live in for the rest of the module.

Look across the whole cluster's recent scheduling decisions:

```bash
kubectl get events -A --field-selector reason=Scheduled | tail -10
```{{exec}}

## How much room is left

A Pod schedules only if its requests fit the node's **Allocatable** minus what's already reserved. Read the worker's ledger:

```bash
kubectl describe node -l '!node-role.kubernetes.io/control-plane' | grep -A6 'Allocated resources'
```{{exec}}

The percentages are requests-of-Allocatable. As long as a new Pod's requests fit under the remaining headroom, it schedules; ask for more than that — or more than any single node has — and it won't. That's not a hypothetical:

```bash
kubectl get nodes -o custom-columns=\
'NODE:.metadata.name,CPU:.status.allocatable.cpu,MEM:.status.allocatable.memory'
```{{exec}}

Note the worker's Allocatable memory — a couple of GiB, not hundreds. A Pod that requests `256Gi` fits *nowhere*, and the scheduler says so in one event. That's breakfix-01. You've now seen healthy placement end to end; read [`LESSON.md`](../LESSON.md) for the *why*, then break it four ways. See `finish.md`.
