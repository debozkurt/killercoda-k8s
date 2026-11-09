# Step 1 — Find the stalled stage

No Pod fails, so the workloads are not the place to start. Read the delivery loop in order: source, then consumers.

## Confirm the symptom

```bash
kubectl get deploy -n app-services
```{{exec}}

Only the fleet's own Deployments. `dialplan`, `message-store` and `voicemail` were never created.

## Read the consumers

```bash
flux get kustomizations
flux get helmreleases
```{{exec}}

All three are `READY False`, and none of the messages is an apply error:

- `apps`: `Source artifact not found, retrying in 30s`
- `message-store`: `HelmChart ... is not ready: no artifact available for GitRepository source 'polyphone-config'`
- `voicemail`: `dependency 'flux-system/message-store' is not ready`

Every message points up the pipeline. The consumers have nothing to apply.

## Read the source

```bash
flux get sources git
```{{exec}}

`polyphone-config` is `READY False` with an empty `REVISION`. The message ends with `couldn't find remote ref "refs/heads/release-2024"`. source-controller asked the git server for the branch `release-2024` and never stored an artifact.

```bash
kubectl describe gitrepository polyphone-config -n flux-system
```{{exec}}

Under `Spec`, `Ref` reads `Branch: release-2024`. Under `Status`, there is no `Artifact` block, and the `Ready` condition has the reason `GitOperationFailed`.

## Ask git which branches exist

```bash
git -C /root/polyphone-config ls-remote --heads origin
```{{exec}}

One branch: `refs/heads/main`. The source names a branch that the repo never had.
