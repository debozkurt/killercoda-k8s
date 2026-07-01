# Step 2 — Fix it and verify

The claim `directory-data` exists (waiting for a consumer); the Deployment just names the wrong one (`directory-store`). Point the Pod template's `claimName` at the claim that's actually there. Unlike a PVC's `storageClassName`, a Pod's `claimName` is freely mutable — you edit the Deployment and it rolls a new Pod.

## Correct the claimName

```bash
kubectl patch deployment directory -n app-services --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/volumes/0/persistentVolumeClaim/claimName","value":"directory-data"}]'
```{{exec}}

Or by hand:

```bash
kubectl edit deployment directory -n app-services
# under volumes: → persistentVolumeClaim:
# change  claimName: directory-store
# to      claimName: directory-data   (the claim that actually exists)
```

Editing the Pod template triggers a rollout: the old `Pending` Pod is replaced by one that mounts `directory-data`. Now that a Pod is finally consuming it, `WaitForFirstConsumer` binds the claim, and the Pod schedules and starts.

(The mirror-image fix is valid too — if the *claim* were the thing misnamed and the Pod were right, you'd create or rename the PVC instead. Fix whichever side is wrong; here the Pod named a claim that never existed.)

## Verify

```bash
kubectl wait --for=condition=Ready pod -l app=directory -n app-services --timeout=60s
kubectl get pods -n app-services -l app=directory
kubectl get deploy directory -n app-services \
  -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}'; echo
```{{exec}}

The `directory` Pod is `Running` and `Ready`; `directory-data` is now `Bound` (a Pod finally consumed it), and the Deployment mounts the claim that existed all along. The volume never changed; only the name the Pod used did. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
