# Step 1 — Diagnose the untolerated taint

Another `Pending` Pod, another `FailedScheduling` event — but read it, because the reason is not "insufficient" anything.

## Confirm Pending, then read the reason

```bash
kubectl get pods -n edge -o wide
kubectl describe pod -n edge -l app=pstn-probe | grep -A6 Events
```{{exec}}

The event reads roughly:

```text
0/2 nodes are available: 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: },
                         1 node(s) had untolerated taint {dedicated: telephony}.
```

Both nodes are refusing the Pod, each for a taint the Pod doesn't tolerate. The control-plane line is the usual one. The new one is the worker: **`{dedicated: telephony}`**. Nothing is short on resources — the node is marked "keep off unless you tolerate `dedicated=telephony`."

## Read the taint on the node

```bash
kubectl describe node -l '!node-role.kubernetes.io/control-plane' | grep -A2 Taints
```{{exec}}

`Taints: dedicated=telephony:NoSchedule`. That's a `NoSchedule` taint — note the rest of the fleet is still `Running` on this same node, because `NoSchedule` blocks *new* scheduling but doesn't evict Pods already there. (Had it been `NoExecute`, the node would have emptied.)

## The Pod has no matching toleration

```bash
kubectl get deploy pstn-probe -n edge -o jsonpath='{.spec.template.spec.tolerations}'; echo
```{{exec}}

Empty. Compare with the DaemonSet that *does* run on a tainted node:

```bash
kubectl get ds sbc-edge -n edge -o jsonpath='{.spec.template.spec.tolerations}'; echo
```{{exec}}

`sbc-edge` tolerates the control-plane taint, which is why it lands there; `pstn-probe` tolerates nothing, which is why it lands nowhere. The fix is one toleration. On to it.
