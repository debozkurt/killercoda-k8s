# Step 1 — Where the fleet landed

The scheduler placed every fleet Pod on a node. Start with the nodes, then see which Pods run where.

## Two nodes, one of them off-limits

```bash
kubectl get nodes
```{{exec}}

Two nodes: one with the `control-plane` role, and one worker. The `-o wide` flag adds a `NODE` column to a Pod listing. Sort by that column to group the Pods by node:

```bash
kubectl get pods -A -o wide --sort-by=.spec.nodeName
```{{exec}}

Nearly every fleet Pod runs on the **worker**. On the control-plane node you find system Pods in `kube-system` and one fleet Pod: `sbc-edge`. A **DaemonSet** is a controller that runs one Pod on each node, and `sbc-edge` is a DaemonSet. A taint explains the rest.

## Why the control-plane node stays empty

A **taint** is a mark on a node that repels every Pod without a matching **toleration**. Read the taints on both nodes:

```bash
kubectl describe nodes | grep -E '^Name:|^Taints:'
```{{exec}}

The control-plane node shows `node-role.kubernetes.io/control-plane:NoSchedule`. kubeadm adds that taint to keep ordinary workloads off the control plane. The worker shows `Taints: <none>`, so the scheduler sends the fleet there.

This asymmetry appears in every scheduling failure in this module. Each `FailedScheduling` message carries one entry for the control-plane taint. That entry is expected. The actionable cause is the worker's entry.

Next: the resource contract that decides whether a Pod fits the worker at all.
