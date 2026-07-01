# Step 1 — Diagnose the coverage gap

There's no failure to chase here — no crash, no `Pending`. The bug is an *absence*. Find the uncovered node, then the reason it was never a candidate.

## DESIRED is the coverage number — and it's short

```bash
kubectl get daemonset -n edge
```{{exec}}

`sbc-edge` shows `DESIRED 2`; `rtp-probe` shows `DESIRED 1`. For a DaemonSet, `DESIRED` isn't a replica count you chose — it's the number of nodes the controller found *eligible* to run the Pod. On a 2-node cluster, `1` means one node was ruled out. See which node each covers:

```bash
kubectl get pods -n edge -o wide
```{{exec}}

Both `sbc-edge` Pods are there — one on the worker, one on the control-plane. `rtp-probe` has a single Pod, on the **worker**. The control-plane node has an `sbc-edge` Pod but no `rtp-probe`. So the difference between these two DaemonSets is whatever lets one onto the control-plane node and not the other.

## The control-plane node is tainted; only sbc-edge tolerates it

```bash
kubectl describe node -l node-role.kubernetes.io/control-plane | grep -A2 Taints
```{{exec}}

`node-role.kubernetes.io/control-plane:NoSchedule` — the taint that keeps ordinary workloads off. A DaemonSet Pod is only eligible for a node whose taints it tolerates, so a Pod without this toleration makes the control-plane node ineligible — which is why it isn't counted in `rtp-probe`'s `DESIRED`. Compare the two DaemonSets' tolerations:

```bash
kubectl get ds sbc-edge -n edge -o jsonpath='{.spec.template.spec.tolerations}'; echo
kubectl get ds rtp-probe -n edge -o jsonpath='{.spec.template.spec.tolerations}'; echo
```{{exec}}

`sbc-edge` tolerates `node-role.kubernetes.io/control-plane`; `rtp-probe` tolerates nothing. That's the entire bug — no error emitted, just a node the DaemonSet decided it couldn't run on and therefore didn't. The fix is the missing toleration.
