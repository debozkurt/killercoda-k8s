# Step 2 — Fix it and verify

The worker carries `dedicated=telephony:NoSchedule`. A toleration matches a taint when its key, value and effect match. Add that toleration to the Pod template.

## Add the matching toleration

The Deployment has no `tolerations` list yet, so the JSON patch creates one:

```bash
kubectl patch deployment pstn-probe -n edge --type=json -p \
  '[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"dedicated","operator":"Equal","value":"telephony","effect":"NoSchedule"}]}]'
```{{exec}}

The template change rolls a new Pod. The control-plane taint still repels it, and that is fine: the Pod needs only one node.

Or by hand:

```bash
kubectl edit deployment pstn-probe -n edge
# under spec.template.spec, add:
#   tolerations:
#     - { key: dedicated, operator: Equal, value: telephony, effect: NoSchedule }
```

## Verify

```bash
kubectl get pods -n edge -o wide
kubectl get deploy pstn-probe -n edge
```{{exec}}

The new Pod lands on the worker and reaches `Running`, and the Deployment reports `1/1`. Read its events:

```bash
kubectl describe pod -n edge -l app=pstn-probe
```{{exec}}

The last event is `Scheduled`, and the `Tolerations:` block now starts with `dedicated=telephony:NoSchedule`. The taint on the node did not change. The Pod gained an exception to it.

A toleration is permission, not attraction. It removes the taint as a reason to refuse the Pod, and it does not pull the Pod toward the node. To reserve a pool for telephony, the team also needs a node affinity on the telephony workloads.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). Then see `finish.md`.
