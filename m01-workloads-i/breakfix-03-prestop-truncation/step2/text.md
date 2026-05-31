# Step 2 — Fix it and verify

The drain takes 15 seconds; the budget is 1. Raise `terminationGracePeriodSeconds` so it comfortably exceeds the drain — don't remove the drain. A common choice is 30 (15s of drain plus headroom for `SIGTERM` handling).

## Apply the fix

```bash
kubectl patch deployment session-broker -n media \
  -p '{"spec":{"template":{"spec":{"terminationGracePeriodSeconds":30}}}}'
```{{exec}}

Or by hand:

```bash
kubectl edit deployment session-broker -n media
# under spec.template.spec, change  terminationGracePeriodSeconds: 1  to  30
```

Changing the Pod template rolls a new ReplicaSet with the corrected budget.

```bash
kubectl rollout status deployment session-broker -n media
```{{exec}}

## Verify the drain now completes

Time a shutdown again. This time the kubelet lets `preStop` finish before killing the container:

```bash
POD=$(kubectl get pod -n media -l app=session-broker -o jsonpath='{.items[0].metadata.name}')
time kubectl delete pod $POD -n media
```{{exec}}

The delete now blocks for **~15 seconds** — the full drain running to completion before the pod exits. That's the difference between a clean rollout and dropped calls. The budget fits the work.

```bash
kubectl get deploy session-broker -n media \
  -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}'; echo
```{{exec}}

`30` — the drain has room to finish.

For self-grading, the precise grace-period accounting, the PID-1 signal-forwarding trap, and the production angle (how to *measure* the right grace period rather than guess), see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
