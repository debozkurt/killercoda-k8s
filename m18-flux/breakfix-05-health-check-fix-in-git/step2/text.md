# Step 2 — Fix it in git and verify

The release commit is the cause, so revert it. A revert is a new commit that undoes the old one, and history keeps both.

## Revert, push, reconcile

```bash
cd /root/polyphone-config
git revert --no-edit HEAD
git push
flux reconcile kustomization apps --with-source
```{{exec}}

`fetched revision` and `applied revision` both name the revert commit. A fix forward, a commit that sets a tag the registry has, works the same way.

## Verify with revisions

```bash
git log --oneline -1
flux get sources git
flux get kustomizations
```{{exec}}

The same hash in all three. `apps` reads `READY True`, so this pass applied the revert and passed its health check.

```bash
kubectl get pods -n app-services -l app=dialplan
```{{exec}}

Two Pods run `nginx:1.25`, and the `ImagePullBackOff` Pod is gone. The next pass applies the same image again, so this fix lasts.
