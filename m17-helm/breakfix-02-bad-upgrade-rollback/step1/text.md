# Step 1 — Success that isn't

Helm reported the upgrade succeeded. The pages say otherwise. Both are right — they're describing different things.

## What Helm thinks

```bash
helm status voicemail -n app-services
```{{exec}}

`STATUS: deployed`, `REVISION: 2`. From Helm's point of view the upgrade worked: it merged values, rendered a valid manifest, and applied it. Helm does not wait for pods to become ready unless you pass `--wait` — so "deployed" means "manifest applied," not "workload healthy."

## What the workload thinks

```bash
kubectl get pods -n app-services -l app=voicemail
```{{exec}}

Two pods `Running`, and a third stuck in `ImagePullBackOff`. The Deployment:

```bash
kubectl get deployment voicemail -n app-services
```{{exec}}

`UP-TO-DATE` is 1, not 2 — the rollout is wedged. The old (good) pods are still serving because the default rolling update won't tear them down until the new pod is ready, and it never will be. `helm status` "deployed" hid a stuck rollout.

## Find the cause

```bash
kubectl describe pod -n app-services -l app=voicemail | grep -A3 "Failed"
```{{exec}}

`Failed to pull image "nginx:1.25-eol-removed"` — the tag the upgrade set doesn't exist.

## Read the history — the recovery path

```bash
helm history voicemail -n app-services
```{{exec}}

```text
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         deployed    Upgrade complete
```

Revision 1 is the last known-good state (image `nginx:1.25`). Confirm what it ran:

```bash
helm get values voicemail -n app-services --revision 1 -a | grep -A2 image
```{{exec}}

Revision 1 used the good tag. You don't need to hand-reconstruct the fix — the release already stored it. Move to step 2 to roll back.
