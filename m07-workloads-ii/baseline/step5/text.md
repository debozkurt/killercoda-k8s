# Step 5 — DaemonSet coverage: one Pod per eligible node

A DaemonSet has no replica count. The set of **eligible nodes** is the Pod count. A node is eligible when its labels match the Pod's `nodeSelector` and affinity, and the Pod tolerates its taints.

## DESIRED counts eligible nodes

```bash
kubectl describe daemonset sbc-edge -n edge
```{{exec}}

Find `Desired Number of Nodes Scheduled:`. It reads 2, so both nodes are eligible. `Pods Status:` shows two Running. The 2 comes from the node list, not from a field you set. Confirm where the Pods run:

```bash
kubectl get pods -n edge -l app=sbc-edge -o wide
```{{exec}}

One Pod is on the worker and one is on the control-plane node. That node carries a taint, so how did `sbc-edge` reach it?

## The toleration that crosses the taint

Read the control-plane node's taint:

```bash
kubectl describe nodes | grep -E '^Name:|^Taints:'
```{{exec}}

The control-plane node carries `node-role.kubernetes.io/control-plane:NoSchedule`. The worker shows `<none>`. Now read the DaemonSet's tolerations. They sit in the Pod template part of the same `describe` output:

```bash
kubectl describe daemonset sbc-edge -n edge | grep -A2 Tolerations
```{{exec}}

The `Tolerations:` line names `node-role.kubernetes.io/control-plane`. Without it, the control-plane node would be ineligible. `DESIRED` would read 1, with no error and no `Pending` Pod. That makes `DESIRED` the DaemonSet's coverage check: compare it with the nodes the agent belongs on.

The tour is complete. Read `LESSON.md` for the why, then break each guarantee in the five scenarios.
