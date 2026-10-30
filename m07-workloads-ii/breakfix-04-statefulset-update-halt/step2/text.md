# Step 2 — Fix it and verify

Roll the template back, then check whether the controller repaired the broken Pod.

## Roll back the template

```bash
kubectl rollout undo statefulset/session-store -n app-services
```{{exec}}

The command restores the previous template. Wait 20 seconds, then check the Pods:

```bash
kubectl get pods -n app-services -l app=session-store -L controller-revision-hash
```{{exec}}

`session-store-2` is still in `ImagePullBackOff`, with its old hash and its old `AGE`. The controller did not replace it. This is the rule from breakfix-02. Under `OrderedReady`, the controller waits for every Pod it created to be Ready before it acts, and `session-store-2` never became Ready.

## Delete the Pod that runs the bad template

```bash
kubectl delete pod session-store-2 -n app-services
kubectl rollout status statefulset/session-store -n app-services --timeout=120s
```{{exec}}

The controller recreates `session-store-2` from the restored template, and the rollout completes. Confirm:

```bash
kubectl get pods -n app-services -l app=session-store -L controller-revision-hash
```{{exec}}

All three Pods are `1/1` and share one hash. Read `AGE`. Ordinals 0 and 1 are older than ordinal 2, because you never restarted them. See [`ANSWER-KEY.md`](../ANSWER-KEY.md) for self-grading, then `finish.md`.
