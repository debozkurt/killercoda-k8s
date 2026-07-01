# Step 2 — Fix it and verify

The readiness probe just needs the right port — 80, where nginx actually serves. Unlike a Service's `clusterIP` (break/fix 01) or a PVC's `storageClassName`, a StatefulSet's Pod template *is* mutable, so a `patch` works:

```bash
kubectl patch statefulset session-cache -n media --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'
```{{exec}}

(Equivalently, `kubectl edit statefulset session-cache -n media` and change the probe `port` to `80`.)

The controller updates `session-cache-0` with the corrected template. Watch the ordered cascade complete — `-0` becomes Ready, then `-1` is created and becomes Ready, then `-2`:

```bash
kubectl rollout status statefulset session-cache -n media --timeout=120s
```{{exec}}

## Verify

```bash
kubectl get statefulset session-cache -n media
kubectl get pods -n media -l app=session-cache
```{{exec}}

`READY 3/3`, and all three ordinals — `session-cache-0`, `-1`, `-2` — are `Running` and `1/1` Ready. The moment ordinal 0 passed its probe, `OrderedReady` unblocked and created the rest in order. That's the tell of this failure class: fix the *first* unready ordinal and the whole set unwedges on its own. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
