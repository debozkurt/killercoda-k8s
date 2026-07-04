# Step 1 — Why the release won't install

The release is stuck but nothing upstream is broken. When a `HelmRelease` won't install and the source is healthy, read *why it says* it's not ready — it may be waiting on purpose.

## Read the release's condition

```bash
flux get helmreleases
```{{exec}}

Two releases show: `message-store` is `READY True`, but `voicemail` is `READY False`. Read voicemail's message: `dependency 'flux-system/message-cache' is not ready`. The release isn't failing to render or install — it's refusing to start because a dependency isn't ready.

Get the full condition:

```bash
kubectl get helmrelease voicemail -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].reason}: {.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```{{exec}}

Reason `DependencyNotReady`, naming `flux-system/message-cache`. `dependsOn` gates a release until the objects it lists are `Ready` — so `voicemail` is waiting for a HelmRelease called `message-cache`.

## Is the dependency real?

A `HelmRelease`'s `dependsOn` references other HelmReleases, so check there — not the Kustomizations:

```bash
flux get helmreleases
```{{exec}}

The backing store is `message-store`, `READY True`. There is no `message-cache` — it doesn't exist, so it can never become ready, so `voicemail` waits forever. Confirm what the release points at:

```bash
kubectl get helmrelease voicemail -n flux-system -o jsonpath='{.spec.dependsOn}{"\n"}'
```{{exec}}

`[{"name":"message-cache"}]`. The dependency is a name that doesn't match any HelmRelease in the cluster. The backing store `voicemail` actually needs is `message-store` — the `dependsOn` is pointing at the wrong name (a stale rename). Move to step 2 to correct it.

## Rule out the other layers (good habit)

```bash
flux get sources git
kubectl get deploy dialplan -n app-services
```{{exec}}

Source `Ready True`, `dialplan` running `2/2`. The rest of the pipeline is healthy — this is isolated to the `voicemail` release's dependency reference.
