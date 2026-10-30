# Step 1 — Time a Pod termination

A slow change with no error is a duration problem. Measure it.

## Watch a Pod leave

Delete one Pod without waiting, then watch it:

```bash
POD=$(kubectl get pods -n media -l app=announce-player -o name | head -1)
kubectl delete $POD -n media --wait=false
kubectl get pods -n media -l app=announce-player -w --request-timeout=60s
```{{exec}}

The old Pod reads `Terminating` and stays that way, while its replacement starts and becomes Ready. Count the seconds. It leaves after about 45. Stop the watch with Ctrl-C.

## Compare with the grace period

Delete another Pod and read its termination state at once:

```bash
POD=$(kubectl get pods -n media -l app=announce-player --no-headers | grep Running | head -1 | cut -d' ' -f1)
kubectl delete pod $POD -n media --wait=false
kubectl describe pod $POD -n media
```{{exec}}

Find `Status:`, which reads Terminating with a countdown, and `Termination Grace Period:`, which reads 45s. The Pod lives for the whole grace period. In `Events:`, a `Killing` event marks the moment the kubelet asked the container to stop. The kubelet sends SIGTERM first and SIGKILL when the budget ends. A container that exits on SIGTERM leaves in a second or two. This one waited for the SIGKILL.

## Read what the container does

```bash
kubectl describe deployment announce-player -n media
```{{exec}}

In the Pod template, find `Command:`. The shell runs `trap '' TERM`, which ignores SIGTERM, then loops forever. The signal arrives and nothing happens. Real apps do this with no handler, or behind a shell wrapper that does not forward the signal. Next: install a handler.
