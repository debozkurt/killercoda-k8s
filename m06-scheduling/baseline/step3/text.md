# Step 3 — Labels, affinity, and tolerations

Requests decide whether a Pod fits a node. Affinity and tolerations decide which nodes the Pod may use at all. The fleet already uses both.

## Node labels are the targets

Node affinity is a query against node labels. The `-L` flag adds a label as a column:

```bash
kubectl get nodes -L disktype
```{{exec}}

The `DISKTYPE` column reads `ssd` on the worker and is empty on the control-plane node. The setup script labeled the worker.

## Node affinity pins the media workloads

A **StatefulSet** is a controller for Pods with stable identities; M07 covers it. The `media-engine` StatefulSet carries a node affinity. Its YAML is long, so filter to the rule:

```bash
kubectl get statefulset media-engine -n media -o yaml | grep -A6 nodeAffinity
```{{exec}}

The rule is `requiredDuringSchedulingIgnoredDuringExecution`, with `key: disktype`, `operator: In` and `values: [ssd]`. `required` makes it a hard filter: the scheduler places these Pods only on a node labeled `disktype=ssd`. `IgnoredDuringExecution` means a later label change does not move a running Pod.

## A toleration lets sbc-edge reach the control plane

The `sbc-edge` DaemonSet runs on both nodes:

```bash
kubectl get daemonset sbc-edge -n edge
```{{exec}}

`DESIRED 2` and `READY 2`. Read the tolerations on its Pods:

```bash
kubectl describe pod -n edge -l app=sbc-edge | grep -A7 Tolerations
```{{exec}}

The first entry is `node-role.kubernetes.io/control-plane:NoSchedule op=Exists`. That toleration is the only reason a fleet Pod runs on the control-plane node. The DaemonSet controller adds the other entries itself, so its Pods survive node trouble.

Compare an ordinary Deployment Pod:

```bash
kubectl describe pod -n media -l app=session-broker | grep -A2 Tolerations
```{{exec}}

Two entries, which Kubernetes adds to every Pod: `node.kubernetes.io/not-ready:NoExecute op=Exists for 300s`, and the same for `unreachable`. When a node fails, its Pods stay bound for 300 seconds, and then the cluster evicts them. There is no control-plane toleration, so the scheduler keeps `session-broker` on the worker.

Next: place a Pod yourself and watch the ledger change.
