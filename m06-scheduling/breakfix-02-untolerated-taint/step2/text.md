# Step 2 — Fix it and verify

The worker is tainted `dedicated=telephony:NoSchedule`. Give `pstn-probe` a toleration whose key, value, and effect match, and the taint stops repelling it.

## Add the matching toleration

```bash
kubectl patch deployment pstn-probe -n edge --type=json -p \
  '[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"dedicated","value":"telephony","operator":"Equal","effect":"NoSchedule"}]}]'
```{{exec}}

The template change rolls a new Pod that tolerates the worker's taint. (The control-plane taint still repels it — that's fine; it only needs one node, and the worker is now open to it.)

Or by hand:

```bash
kubectl edit deployment pstn-probe -n edge
# under spec.template.spec, add:
#   tolerations:
#     - { key: dedicated, value: telephony, operator: Equal, effect: NoSchedule }
```

## Verify

```bash
kubectl get pods -n edge -o wide
kubectl get deploy pstn-probe -n edge
```{{exec}}

The new Pod schedules onto the worker and goes `Running`; the Deployment reports `1/1`. Confirm the reason it's now allowed:

```bash
kubectl describe pod -n edge -l app=pstn-probe | grep -A3 Events
```{{exec}}

`Scheduled … Successfully assigned edge/pstn-probe-… to <worker>`. The taint on the node never changed — the Pod earned an exception to it. A toleration doesn't *force* a Pod onto a tainted node; it only removes the taint as a reason to keep it off. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
