# Step 1 — Why nothing is reconciling

The workloads are missing but nothing crashed. In Flux, "delivered nothing" almost always means a stalled reconcile, not a broken workload. Read the pipeline top-down.

## Confirm the workloads are absent

```bash
kubectl get deploy -n app-services -l 'app in (dialplan,voicemail)'
```{{exec}}

Nothing. The `apps` Kustomization and the `voicemail` HelmRelease never applied their objects.

## Read the source first

The source is the top of the pipeline. Start there, always:

```bash
flux get sources git
```{{exec}}

`polyphone-config` is `READY False`. Read the message — it names a git error, something like `couldn't find remote ref 'refs/heads/release-2024'`. source-controller tried to check out a ref the server doesn't have, so it never produced an artifact.

Get the full condition:

```bash
kubectl describe gitrepository polyphone-config -n flux-system | sed -n '/Conditions:/,$p'
```{{exec}}

The `Ready` condition is `False` with the reason and the failing ref. This is the whole diagnosis — the source can't fetch, so there is no content to apply.

## Confirm the downstream is only *waiting*

```bash
flux get kustomizations
```{{exec}}

`apps` is not ready either — but its message points back at the source (no artifact). The Kustomization isn't broken; it has nothing to build. Same story for the HelmReleases:

```bash
flux get helmreleases
```{{exec}}

Everything downstream is blocked on one thing: the source. That's the point of reading top-down — one red source explains every red consumer.

## What branch does the repo actually have?

```bash
kubectl get gitrepository polyphone-config -n flux-system -o jsonpath='{.spec.ref}{"\n"}'
```{{exec}}

`{"branch":"release-2024"}`. The repo was seeded with a single branch, `main`. The source is pointed at a branch that was never created. Move to step 2 to fix it.
