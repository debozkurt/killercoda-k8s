# Step 2 — Fix it and verify

Give `rtp-probe` the toleration that `sbc-edge` carries. When the Pod tolerates the taint, the control-plane node becomes eligible and the controller creates a Pod there.

## Add the control-plane toleration

```bash
kubectl patch daemonset rtp-probe -n edge --type=json -p \
  '[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule"}]}]'
```{{exec}}

The operator `Exists` tolerates the taint whatever its value, the same form `sbc-edge` uses. The patch edits the Pod template, and the controller evaluates every node again.

Or by hand:

```bash
kubectl edit daemonset rtp-probe -n edge
# under spec.template.spec, add:
#   tolerations:
#     - { key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule }
```

## Verify full coverage

```bash
kubectl get daemonset rtp-probe -n edge
kubectl get pods -n edge -l app=rtp-probe -o wide
```{{exec}}

`DESIRED`, `CURRENT` and `READY` all read 2, and a second Pod now runs on the control-plane node. The node did not change, and its taint is still there. The Pod now tolerates it. `DESIRED` equal to the node count is the sign that coverage is complete. See [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m07-workloads-ii/ANSWER-KEY.md) for self-grading, then `finish.md`.
