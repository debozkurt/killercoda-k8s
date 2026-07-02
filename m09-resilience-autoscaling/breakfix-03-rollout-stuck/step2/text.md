# Step 2 — Roll back and verify

The new revision is broken and the old one is still serving. The fastest safe move is to rewind to the last good revision — that's what rollback is for.

## Undo the rollout

```bash
kubectl rollout undo deployment/portal-web -n admin-portal
kubectl rollout status deployment/portal-web -n admin-portal
```{{exec}}

`rollout undo` re-applies revision 1's template (the good `nginx:1.25`) and rolls forward to it. Because the good image pulls instantly, `rollout status` returns `successfully rolled out` this time instead of hanging.

## Verify the Deployment is fully healthy

```bash
kubectl get deployment portal-web -n admin-portal
kubectl get pods -n admin-portal -l app=portal-web
```{{exec}}

`READY 2/2`, `UP-TO-DATE 2`, `AVAILABLE 2`, and every Pod `Running` — no `ImagePullBackOff`. The new (bad) ReplicaSet is scaled back to `0`. Confirm the image:

```bash
kubectl get deployment portal-web -n admin-portal \
  -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```{{exec}}

Back to `nginx:1.25`. The rollout is complete and the service is on a known-good version.

## Rollback vs. roll-forward, and why it stayed up

- **Rollback is the emergency lever**: one command, back to a version you know worked, no waiting on a fix. `kubectl rollout undo --to-revision=N` targets a specific revision (see `rollout history`); plain `undo` goes back one.
- **Roll-forward** — pushing a *corrected* image (`kubectl set image ...` with a real tag) — is the alternative when the fix is trivial and you'd rather not lose the new revision's other changes. Either resolves a stuck rollout; rollback is usually faster under pressure.
- **The service never dropped** because the default `maxUnavailable` kept both old Pods running until a new one was Ready — and a new one never was. That "careful" default is what turned a bad deploy into a stalled rollout instead of an outage. `progressDeadlineSeconds` (set to 60s here) is what surfaced it as `ProgressDeadlineExceeded` rather than an invisible wait — but it only *reports*; a human or a pipeline still has to act.

The durable prevention is upstream: a readiness probe so a bad Pod is never counted Ready, and a pipeline that verifies the image exists (and ideally canaries the release) before it reaches a cluster.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
