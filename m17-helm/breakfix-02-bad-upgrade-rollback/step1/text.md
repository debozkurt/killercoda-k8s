# Step 1 — A green status and a stuck rollout

Helm and the workload disagree. Read both.

## What Helm reports

```bash
helm status voicemail -n app-services | head -7
```{{exec}}

`STATUS: deployed`, `REVISION: 2`. In Helm 4, `helm upgrade` does not wait for Pods unless you pass `--wait`. `deployed` means the apply succeeded.

## What the workload reports

```bash
kubectl get pods -n app-services -l app=voicemail
kubectl get deployment voicemail -n app-services -o wide
```{{exec}}

Two Pods are `Running` and one is in `ErrImagePull` or `ImagePullBackOff`. The Deployment reads `READY` 2/2 and `UP-TO-DATE` 1: the old Pods still serve, and the rolling update cannot replace them. The `IMAGES` column shows the tag the upgrade set.

```bash
kubectl describe pod <name-of-the-stuck-pod> -n app-services
```

Read the `Warning  Failed` line in `Events:`. It says `Failed to pull image "nginx:1.25.99"` with a not-found error: that tag does not exist.

## Find the last good revision

```bash
helm history voicemail -n app-services
```{{exec}}

Revision 1 is `superseded`, `Install complete`. Revision 2 is `deployed`, `Upgrade complete`. Compare the inputs of the two revisions:

```bash
helm get values voicemail -n app-services --revision 1
helm get values voicemail -n app-services --revision 2
```{{exec}}

Revision 2 adds `image.tag: 1.25.99`. Revision 1 used the chart's tag. The release record already holds the good state, so you do not need to rebuild it by hand.
