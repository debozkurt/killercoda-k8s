# Step 1 — Diagnose the coverage gap

No failure exists to chase here. The bug is an absence. Find the uncovered node, then find why it was never a candidate.

## DESIRED is the coverage number, and it is short

```bash
kubectl get daemonset -n edge
```{{exec}}

`sbc-edge` shows `DESIRED` 2, and `rtp-probe` shows `DESIRED` 1. A DaemonSet's `DESIRED` is the number of nodes the controller found **eligible**. On a 2-node cluster, 1 means the controller ruled out one node. See which node each DaemonSet covers:

```bash
kubectl get pods -n edge -o wide
```{{exec}}

Read the `NODE` column. Both `sbc-edge` Pods exist, one per node. `rtp-probe` has one Pod, on the worker. The control-plane node has no `rtp-probe` Pod. Whatever lets `sbc-edge` onto that node, `rtp-probe` lacks.

## The control-plane node is tainted, and only sbc-edge tolerates it

```bash
kubectl describe nodes | grep -E '^Name:|^Taints:'
```{{exec}}

The control-plane node carries `node-role.kubernetes.io/control-plane:NoSchedule`. A DaemonSet Pod is eligible for a node only if it tolerates the node's taints. Compare the two templates:

```bash
kubectl describe daemonset sbc-edge rtp-probe -n edge | grep -E '^Name:|Tolerations:'
```{{exec}}

The `Tolerations:` line for `sbc-edge` names `node-role.kubernetes.io/control-plane`. The line for `rtp-probe` shows none. Without the toleration, the control-plane node is ineligible. The controller did not try to place a Pod there, so no `Pending` Pod and no event exist. Next: add the toleration.
