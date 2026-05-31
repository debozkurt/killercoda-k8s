# Step 2 — Fix it and verify

The container is healthy; the liveness probe is wrong. Point it at a path the app actually serves (`/`), or, if there's no real health endpoint, remove the liveness probe rather than leave a lying one in place.

## Apply the fix

Edit the Deployment — never the Pods. The ReplicaSet replaces Pods; a change to a live Pod evaporates. Patch the probe path to `/`:

```bash
kubectl patch deployment route-engine -n call-routing --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/path","value":"/"}]'
```{{exec}}

Or open it and edit by hand:

```bash
kubectl edit deployment route-engine -n call-routing
# under livenessProbe.httpGet, change  path: /healthz  to  path: /
```

Changing the Pod template triggers a rolling update — a new ReplicaSet with the corrected probe.

## Watch the rollout converge

```bash
kubectl rollout status deployment route-engine -n call-routing
```{{exec}}

You should see `successfully rolled out` within ~30 seconds. The new Pods pass `/` (nginx returns `200`), so liveness is satisfied and the kubelet stops killing them.

## Confirm the loop is broken

```bash
kubectl get pods -n call-routing
```{{exec}}

Two pods, `Running`, `1/1 READY`, and — the proof — `RESTARTS` no longer climbing. Watch for a few seconds to be sure:

```bash
kubectl get pods -n call-routing -w
```{{exec}}

A stable restart count is the signal the loop is dead. (Ctrl-C to stop watching.)

For self-grading, the real-crash-vs-probe distinction, and the production fix (this belongs in `platform-gitops`, not a live patch), see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
