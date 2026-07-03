# Step 2 — Roll back and verify

Revision 1 is known-good. Roll the release back to it.

## Roll back to revision 1

```bash
helm rollback voicemail 1 -n app-services
```{{exec}}

A rollback re-applies revision 1's manifests as a **new** revision (3). It's a forward action, not a delete — the bad revision 2 stays in the history for the record.

Watch the stuck pod clear:

```bash
kubectl get pods -n app-services -l app=voicemail -w
```{{exec}}

The `ImagePullBackOff` pod disappears (its ReplicaSet scales to zero) and you're left with two `Running` pods on the good image. Press `Ctrl-C` when it settles.

## Verify

```bash
helm history voicemail -n app-services
```{{exec}}

Revision 3, `Rollback to 1`, `deployed`.

```bash
kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl get deployment voicemail -n app-services
```{{exec}}

Image is back to `nginx:1.25`; `UP-TO-DATE` matches the replica count — the rollout is complete.

## Why not `kubectl rollout undo`?

`kubectl rollout undo deployment/voicemail` would also swap the Deployment back to its old ReplicaSet — and it would leave Helm's stored release still pointing at the broken revision 2. The next `helm upgrade` (or a GitOps reconcile) re-applies revision 2 and breaks it again. For a Helm-managed workload, recover *through Helm* so the release history and the live objects stay in agreement. See [ANSWER-KEY.md](../ANSWER-KEY.md) for the drift discussion and the real fix (correct the tag in git, then roll forward).

You're done with breakfix-02. See `finish.md`.
