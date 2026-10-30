# Step 2 — Fix it and verify

## Handle SIGTERM

Replace the ignore with a handler. `trap exit TERM` makes the shell exit when the signal arrives:

```bash
kubectl patch deployment announce-player -n media --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/command","value":["sh","-c","trap exit TERM; while true; do sleep 1; done"]}]'
kubectl rollout status deployment/announce-player -n media --timeout=120s
```{{exec}}

The rollout finishes before the old Pods are gone. They still ignore SIGTERM, so each lingers in `Terminating` for 45 seconds. The new Pods do not. Wait until no Pod reads `Terminating`:

```bash
kubectl get pods -n media -l app=announce-player
```{{exec}}

## Verify

Time a delete. It returns in a few seconds:

```bash
POD=$(kubectl get pods -n media -l app=announce-player --no-headers | grep Running | head -1 | cut -d' ' -f1)
time kubectl delete pod $POD -n media
```{{exec}}

A handler is the fix. A shorter `terminationGracePeriodSeconds` only shortens the wait, and SIGKILL still cuts off in-flight work. A real app needs a handler that stops taking new work and finishes in-flight requests.

See [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m09-resilience-autoscaling/ANSWER-KEY.md) for self-grading, then `finish.md`.
