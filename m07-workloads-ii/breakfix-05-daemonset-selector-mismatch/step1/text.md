# Step 1 — Diagnose the empty DaemonSet

Last scenario, `DESIRED` was one short of the node count. Here it is zero. Start with the same numbers.

## DESIRED is zero

```bash
kubectl get daemonset -A
```{{exec}}

`disk-exporter` shows `DESIRED` 0, and its `NODE SELECTOR` column reads `disktype=nvme`. `sbc-edge` shows `DESIRED` 2. No Pod exists, so no Pod can be `Pending` and no scheduler event exists. A Deployment with the same selector would show a `Pending` Pod with a `FailedScheduling` event. A DaemonSet creates no Pod for a node it finds ineligible.

```bash
kubectl describe daemonset disk-exporter -n media
```{{exec}}

Read three lines. `Desired Number of Nodes Scheduled:` is 0. `Node-Selectors:` reads `disktype=nvme`. The `Events:` block is empty or shows only creation events.

## What the nodes carry

```bash
kubectl get nodes -L disktype
```{{exec}}

The `DISKTYPE` column reads `ssd` on the worker and is empty on the control-plane node. No node carries `disktype=nvme`, so the controller found no eligible node. The selector asks for a label from another region's node pool. Next: fix the selector.
