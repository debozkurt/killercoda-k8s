# Step 1 — Diagnose the untolerated taint

Another `Pending` Pod, and another `FailedScheduling` event. Read the reason, because this time nothing is short.

## Confirm Pending, then read the reason

```bash
kubectl get pods -n edge -o wide
kubectl describe pod -n edge -l app=pstn-probe
```{{exec}}

The `FailedScheduling` event at the bottom reads:

```text
0/2 nodes are available: 1 node(s) had untolerated taint {dedicated: telephony},
1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: ...
```

Both nodes refuse the Pod, each for a taint the Pod does not tolerate. The control-plane entry is the usual one. The new entry belongs to the worker: **`{dedicated: telephony}`**. Now read the `Tolerations:` block higher up in the same output. It lists only `not-ready` and `unreachable`, the two that Kubernetes adds to every Pod.

## Read the taint on the node

Taints live on the node, so `describe pod` never shows them in full:

```bash
kubectl describe nodes | grep -E '^Name:|^Taints:'
```{{exec}}

The worker reads `Taints: dedicated=telephony:NoSchedule`. The docs define that effect: "No new Pods will be scheduled on the tainted node unless they have a matching toleration. Pods currently running on the node are **not** evicted."

Confirm the second half:

```bash
kubectl get pods -A -o wide --sort-by=.spec.nodeName
```{{exec}}

The fleet still runs on the worker. The taint gates new placement only. A `NoExecute` taint would have emptied the node.

## Compare a Pod that tolerates a taint

```bash
kubectl describe pod -n edge -l app=sbc-edge | grep -A7 Tolerations
```{{exec}}

`sbc-edge` tolerates `node-role.kubernetes.io/control-plane:NoSchedule`, so it lands on the control-plane node. `pstn-probe` tolerates neither taint, so it lands nowhere. The fix is one toleration.
