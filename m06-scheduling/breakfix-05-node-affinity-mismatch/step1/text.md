# Step 1 — Diagnose the unmatched selector

A fourth filter, and a fourth reason. Read it before you assume anything.

## Confirm Pending, then read the reason

```bash
kubectl get pods -n media -l app=conference-mixer -o wide
kubectl describe pod -n media -l app=conference-mixer
```{{exec}}

The `FailedScheduling` event reads:

```text
0/2 nodes are available: 1 node(s) didn't match Pod's node affinity/selector,
1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: ...
```

Past the control-plane entry, the worker's reason is **`didn't match Pod's node affinity/selector`**. The worker passed the taint filter and failed the next one: the Pod asks for a node label the worker does not carry.

Higher up in the same output, the `Node-Selectors:` line reads `disktype=nvme`. A **`nodeSelector`** is the simplest node affinity. The docs define it: "Kubernetes only schedules the Pod onto nodes that have each of the labels you specify."

## Read what the nodes carry

```bash
kubectl get nodes -L disktype
```{{exec}}

The `DISKTYPE` column reads `ssd` on the worker and is empty on the control-plane node. No node carries `disktype=nvme`, so the hard filter removes every node.

## Compare a healthy workload

`media-engine` also needs a fast disk, and it runs:

```bash
kubectl get statefulset media-engine -n media -o yaml | grep -A6 nodeAffinity
```{{exec}}

Its rule asks for `disktype` `In` `[ssd]`, the label this cluster uses. `conference-mixer` asks for the label another region uses. The selector is wrong. The node's label is right.

Next: correct the selector.
