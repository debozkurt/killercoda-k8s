# Step 2 — Fix it and verify

Point the readiness probe at port 80, where the container serves. Once Pod-0 can pass its probe and go Ready, `OrderedReady` releases the gate and the controller creates the ordinals behind it.

## Correct the probe's port

```bash
kubectl patch statefulset session-store -n app-services --type=json -p \
  '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'
```{{exec}}

Changing the Pod template rolls the StatefulSet: under the default `RollingUpdate` strategy the controller recreates `session-store-0` with the corrected probe. If it doesn't re-roll within a few seconds, delete Pod-0 to let it come back on the new template:

```bash
kubectl delete pod session-store-0 -n app-services
```{{exec}}

The replacement Pod-0 keeps its name and its PVC — same ordinal, same storage.

## Watch the set unblock

```bash
kubectl rollout status statefulset/session-store -n app-services --timeout=120s
```{{exec}}

Once Pod-0 is Ready, `session-store-1` is created, then `session-store-2` — in order, each waiting for the one before. Confirm:

```bash
kubectl get statefulset session-store -n app-services
kubectl get pods -n app-services -l app=session-store
```{{exec}}

`READY 3/3`, and all three ordinals `Running` and `1/1`. Nothing about the fix was "restart everything" — you corrected one field, Pod-0 passed its probe, and the ordered rollout finished itself. That's the lesson: in a StatefulSet, un-readiness of one Pod isn't a one-Pod problem — it's a rollout-wide stop. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
