# Step 2 — Roll back and verify

The new revision is broken, and the old one still serves. Rewind to the last good revision.

## Undo the rollout

```bash
kubectl rollout undo deployment/portal-web -n admin-portal
kubectl rollout status deployment/portal-web -n admin-portal
```{{exec}}

`rollout undo` re-applies revision 1's template and rolls forward to it. The good image pulls at once, so `rollout status` now reports successfully rolled out.

## Verify

```bash
kubectl get deployment portal-web -n admin-portal
kubectl describe deployment portal-web -n admin-portal
```{{exec}}

READY reads 2/2 and UP-TO-DATE reads 2. In the Pod template, `Image:` is back to nginx:1.25. The broken ReplicaSet is scaled to 0.

The service stayed up because `maxUnavailable` kept both old Pods until a new one was Ready. `progressDeadlineSeconds` (60 here) surfaced the stall and nothing more. A person or a pipeline must act. Rolling forward with a corrected `kubectl set image` is the alternative when the fix is trivial.

See [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m09-resilience-autoscaling/ANSWER-KEY.md) for self-grading, then `finish.md`.
