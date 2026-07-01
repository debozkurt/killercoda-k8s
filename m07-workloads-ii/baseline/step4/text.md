# Step 4 — DaemonSet: one Pod per node

A DaemonSet has no replica count. Its size *is* the node set — one Pod per eligible node. See how `sbc-edge` covers this cluster.

## Desired = eligible nodes, not a replica number

```bash
kubectl get daemonset sbc-edge -n edge
```{{exec}}

`DESIRED 2  CURRENT 2  READY 2` — one Pod per node, both up. That `2` is computed from the node list, not set by you:

```bash
kubectl get pods -n edge -l app=sbc-edge -o wide
```{{exec}}

One Pod on the worker, one on the control-plane node. But the control-plane is tainted to keep ordinary workloads off — so how does `sbc-edge` land there?

## The toleration that reaches the control-plane

```bash
kubectl get ds sbc-edge -n edge -o jsonpath='{.spec.template.spec.tolerations}'; echo
```{{exec}}

It tolerates `node-role.kubernetes.io/control-plane`. That's the exception that lets a "one per node" agent onto the tainted node. Read the taint it's matching:

```bash
kubectl describe node -l node-role.kubernetes.io/control-plane | grep -A2 Taints
```{{exec}}

`node-role.kubernetes.io/control-plane:NoSchedule`. Without the matching toleration, the control-plane node wouldn't be *eligible*, and `DESIRED` would be `1` — the node silently uncovered, no error. That coverage number is the DaemonSet's health check: `DESIRED` should equal the count of nodes the agent belongs on.

That's the healthy shape of both controllers. Read `LESSON.md` for the *why*, then break each guarantee in the three scenarios.
