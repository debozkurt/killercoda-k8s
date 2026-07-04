# Step 1 — Why the release won't install

The release is stuck but nothing upstream is broken. When a `HelmRelease` won't install and the source is healthy, read *why it says* it's not ready — it may be waiting on purpose.

## Read the release's condition

```bash
flux get helmreleases
```{{exec}}

`voicemail` is `READY False`. Read the message: `dependency 'flux-system/platform-config' is not ready`. The release isn't failing to render or install — it's refusing to start because a dependency isn't ready.

Get the full condition:

```bash
kubectl get helmrelease voicemail -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].reason}: {.status.conditions[?(@.type=="Ready")].message}{"\n"}'
```{{exec}}

Reason `DependencyNotReady`, naming `flux-system/platform-config`. `dependsOn` gates a release until the objects it lists are `Ready` — so `voicemail` is waiting for a Kustomization called `platform-config`.

## Is the dependency real?

```bash
flux get kustomizations
```{{exec}}

There is one Kustomization: `apps`, `READY True`. There is no `platform-config` — it doesn't exist, so it can never become ready, so `voicemail` waits forever. Confirm what the release points at:

```bash
kubectl get helmrelease voicemail -n flux-system -o jsonpath='{.spec.dependsOn}{"\n"}'
```{{exec}}

`[{"name":"platform-config"}]`. The dependency is a name that doesn't match anything in the cluster. The Kustomization that actually applies the platform config is `apps` — the `dependsOn` is pointing at the wrong name (a rename or typo). Move to step 2 to correct it.

## Rule out the other layers (good habit)

```bash
flux get sources git
kubectl get deploy dialplan -n app-services
```{{exec}}

Source `Ready True`, `dialplan` running `2/2`. The rest of the pipeline is healthy — this is isolated to the `voicemail` release's dependency reference.
