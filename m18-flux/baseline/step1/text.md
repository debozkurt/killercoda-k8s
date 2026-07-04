# Step 1 — Flux and its sources

Flux is a set of controllers running in the `flux-system` namespace. Each owns one job: source-controller fetches, kustomize-controller and helm-controller apply. Start by confirming they're healthy and reading the source they fetch from.

## Confirm the controllers are up

```bash
flux check
```{{exec}}

You should see the three controllers (`source-controller`, `kustomize-controller`, `helm-controller`) with green checks. These are ordinary Deployments — `kubectl get deploy -n flux-system` shows them too.

## Read the source

A `GitRepository` is a **source**: it clones a git URL on an interval and packages the result as an artifact other objects consume.

```bash
flux get sources git
```{{exec}}

One source: `polyphone-config`, `READY True`, with a message like `stored artifact for revision 'main@sha1:...'`. That revision is the exact commit Flux fetched — the content it will hand to consumers.

Look at the object itself:

```bash
kubectl get gitrepository polyphone-config -n flux-system -o yaml | grep -A15 '^spec:'
```{{exec}}

`spec.url` points at the in-cluster git server; `spec.ref.branch` is `main`; `spec.interval` is `1m`. Every minute source-controller re-checks the branch and re-packages only if the revision changed.

The repo is mirrored on disk so you can read what Flux is delivering:

```bash
ls -R /root/polyphone-config
```{{exec}}

An `apps/` directory of plain manifests and a `charts/voicemail/` Helm chart. Those are the two things the consumers below apply.

## See everything at once

```bash
flux get all
```{{exec}}

Sources, Kustomizations, and HelmReleases in one view — the whole pipeline and each object's `Ready` state. This is the first command at 3am.

## Verify

```bash
kubectl get gitrepository polyphone-config -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}'
```{{exec}}

`True` — the source has a good artifact. Move on to step 2.
