# Step 2 — Fix it and verify

Give `rtp-probe` the same control-plane toleration `sbc-edge` carries. The moment the Pod tolerates the taint, the control-plane node becomes eligible and the DaemonSet places a Pod there.

## Add the control-plane toleration

```bash
kubectl patch daemonset rtp-probe -n edge --type=json -p \
  '[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule"}]}]'
```{{exec}}

`operator: Exists` tolerates the taint regardless of value — the same form `sbc-edge` uses. This edits the DaemonSet's Pod template; the controller re-evaluates every node against the new tolerations.

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
kubectl get pods -n edge -o wide -l app=rtp-probe
```{{exec}}

`DESIRED 2  CURRENT 2  READY 2`, and a second `rtp-probe` Pod now runs on the control-plane node alongside the worker's. The control-plane node didn't change — its taint is still there. What changed is that `rtp-probe` now tolerates it, so the controller counts it as an eligible node and covers it. `DESIRED` matching the node count is the signal that coverage is complete. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
