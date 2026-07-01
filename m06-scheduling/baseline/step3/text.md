# Step 3 — Steering placement: affinity and taints

Requests decide *whether* a Pod fits a node. Affinity and tolerations decide *which* node it prefers or is allowed on. The fleet already uses both.

## Node labels are the targets

```bash
kubectl get nodes --show-labels | tr ',' '\n' | grep -E 'hostname|disktype|control-plane'
```{{exec}}

The worker carries `disktype=ssd` (the lab adds it); the control-plane carries `node-role.kubernetes.io/control-plane`. Affinity rules and `nodeSelector`s are just queries against labels like these.

## nodeAffinity pins the media workloads

```bash
kubectl get statefulset media-engine -n media \
  -o jsonpath='{.spec.template.spec.affinity.nodeAffinity}'; echo
```{{exec}}

`media-engine` (and `transcoder`) **require** `disktype in [ssd]` — a `requiredDuringSchedulingIgnoredDuringExecution` node affinity. The only node with that label is the worker, so that's where they go. Point this at a label no node has, and the Pod would be `Pending` with `didn't match Pod's node affinity/selector` — the same filter, self-inflicted.

## A toleration is how sbc-edge reaches the control-plane

The `sbc-edge` DaemonSet runs on **both** nodes, control-plane included — because it tolerates the taint that keeps everyone else off:

```bash
kubectl get daemonset sbc-edge -n edge
kubectl get ds sbc-edge -n edge -o jsonpath='{.spec.template.spec.tolerations}'; echo
```{{exec}}

`DESIRED 2 / READY 2`, and the toleration matches `node-role.kubernetes.io/control-plane:NoSchedule`. That toleration is the *only* reason a Pod runs on the control-plane node. Every other workload omits it, which is why they all sit on the worker. Keep this contrast in mind — breakfix-02 is a workload that *should* have had a toleration and doesn't. Next: the scheduler's own record of these decisions.
