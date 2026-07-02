# Step 2 — Fix it and verify

The readiness probe just needs the right port: 80, where nginx actually serves. Unlike a Service's `clusterIP` (break/fix 01) or a PVC's `storageClassName`, a StatefulSet's Pod template *is* mutable, so a `patch` works:

```bash
kubectl patch statefulset session-cache -n media --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'
```{{exec}}

(Equivalently, `kubectl edit statefulset session-cache -n media` and change the probe `port` to `80`.)

Patching the template is necessary but not sufficient. Check the Pod:

```bash
kubectl get pods -n media -l app=session-cache
```{{exec}}

`session-cache-0` is *still* `0/1`, and still the only Pod. This is a documented `OrderedReady` behavior (a "forced rollback"): the controller will not roll a corrected template onto a Pod that was never Ready. It keeps waiting for ordinal 0 to become Ready before it will touch it, but ordinal 0 is running the old, broken revision, so it never will. The set is stuck on itself.

The escape is to delete the Pod running the bad revision. Its replacement is created fresh from the *current*, corrected template:

```bash
kubectl delete pod session-cache-0 -n media
```{{exec}}

The new `session-cache-0` comes up on port 80, passes its probe, and `OrderedReady` unblocks — creating `-1` then `-2` in order:

```bash
kubectl rollout status statefulset session-cache -n media --timeout=120s
```{{exec}}

## Verify

```bash
kubectl get statefulset session-cache -n media
kubectl get pods -n media -l app=session-cache
```{{exec}}

`READY 3/3`, and all three ordinals — `session-cache-0`, `-1`, `-2` — are `Running` and `1/1` Ready. The moment ordinal 0 passed its probe, `OrderedReady` unblocked and created the rest in order. That's the tell of this failure class: fix the *first* unready ordinal — and, because the template fix won't reroll a never-Ready Pod, delete that Pod so the fix takes — and the whole set unwedges from there. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
