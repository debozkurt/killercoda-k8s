# Step 2 — Fix it and verify

The source points at `release-2024`; the repo only has `main`. Point the `GitRepository` at the branch that exists.

## Correct the ref

```bash
kubectl patch gitrepository polyphone-config -n flux-system \
  --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
```{{exec}}

Then force source-controller to re-fetch immediately instead of waiting out the interval:

```bash
flux reconcile source git polyphone-config
```{{exec}}

The command returns once the artifact is stored. Confirm the source recovered:

```bash
flux get sources git
```{{exec}}

`READY True`, with `stored artifact for revision 'main@sha1:...'`. The source is feeding the pipeline again.

## Let the consumers catch up

The Kustomization and HelmRelease will reconcile on their own interval; nudge them so you see it now:

```bash
flux reconcile kustomization apps --with-source
```{{exec}}

```bash
kubectl get deploy -n app-services -l 'app in (dialplan,voicemail)'
```{{exec}}

`dialplan` appears and becomes ready; `voicemail` follows once its dependency (`apps`) is ready and helm-controller installs it. Give it a few seconds and re-run the `get` if `voicemail` isn't up yet.

## The durable fix

Patching the live `GitRepository` fixes this cluster. In a bootstrapped setup the `GitRepository` manifest itself lives in git, so the real fix is a reviewed commit correcting `spec.ref.branch` — otherwise the next `flux bootstrap` or reconcile of Flux's own config reapplies `release-2024`. For the triage-vs-git-source contrast, see [ANSWER-KEY.md](../ANSWER-KEY.md).

You're done with breakfix-01. See `finish.md`.
