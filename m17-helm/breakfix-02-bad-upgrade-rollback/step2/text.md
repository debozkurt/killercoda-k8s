# Step 2 — Roll back through Helm

Recover through Helm, so that the release record and the live Deployment describe the same revision.

## Roll back to revision 1

```bash
helm rollback voicemail 1 -n app-services
kubectl rollout status deployment/voicemail -n app-services --timeout=60s
```{{exec}}

Helm re-applies revision 1's manifest as revision 3. The Deployment scales the failed ReplicaSet to zero and the rollout completes.

## Verify

```bash
helm history voicemail -n app-services
kubectl get deployment voicemail -n app-services -o wide
```{{exec}}

Revision 3 reads `deployed`, `Rollback to 1`. Revision 2 stays in the history. `IMAGES` reads nginx:1.25, and `UP-TO-DATE` equals `READY`.

## Why not `kubectl rollout undo`

`kubectl rollout undo deployment/voicemail` also restores the old Pod template. It leaves two problems. The release record still says revision 2 with the bad tag. And in Helm 4, `kubectl` now owns the image field, so the next `helm upgrade` fails with `conflict with "kubectl" ... .spec.template.spec.containers[name="app"].image`. With `--force-conflicts`, that upgrade would apply the bad tag again.

The rollback is the incident fix. The durable fix corrects the tag in the values file in git and rolls forward. [ANSWER-KEY.md](https://github.com/debozkurt/killercoda-k8s/blob/main/m17-helm/ANSWER-KEY.md) has the comparison.
