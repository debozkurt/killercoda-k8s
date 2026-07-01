# Step 1 — Where the fleet landed

The scheduler placed every fleet Pod on a node. Start by seeing the nodes and who ran where.

## Two nodes, one of them off-limits

```bash
kubectl get nodes
```{{exec}}

Two nodes: one `control-plane`, one worker. Now look at where the fleet's Pods actually run — `-o wide` adds the `NODE` column:

```bash
kubectl get pods -A -o wide --sort-by='.spec.nodeName' | grep -v kube-system
```{{exec}}

Almost everything is on the **worker**. The only fleet Pod on the control-plane node is the `sbc-edge` DaemonSet (which is supposed to run everywhere). That's not luck — it's a taint.

## Why the control-plane is empty

```bash
kubectl describe node -l node-role.kubernetes.io/control-plane | grep -A2 Taints
```{{exec}}

The control-plane node carries `node-role.kubernetes.io/control-plane:NoSchedule`. A **taint** repels every Pod that doesn't explicitly **tolerate** it, so the scheduler won't place ordinary workloads here — kubeadm adds this taint on purpose to keep user workloads off the control plane. The worker has no such taint, so the fleet piles onto it.

Confirm the worker is clean:

```bash
kubectl describe node -l '!node-role.kubernetes.io/control-plane' | grep -A2 Taints
```{{exec}}

`Taints: <none>`. That asymmetry — one node tainted, one open — is why *every* scheduling failure you'll debug in this module shows a `{node-role.kubernetes.io/control-plane}` line in its event. It's expected noise; the real cause is always on the worker's line. Next: the resource contract that decides whether a Pod fits that worker at all.
