# Step 4 — HelmRelease and dependsOn

A **`HelmRelease`** makes the helm-controller run the Helm install and upgrade from M17. The chart here is a directory inside the same git repo.

## Read the releases

```bash
flux get helmreleases
```{{exec}}

`message-store` and `voicemail` are both `READY True`, and each message names an installed release revision.

```bash
kubectl describe helmrelease voicemail -n flux-system
```{{exec}}

Under `Spec`, read `Chart` (the path `./charts/voicemail` in the `GitRepository`), `Target Namespace: app-services`, `Values` and `Depends On`.

## Find the Helm release record

The helm-controller stores releases the way the `helm` CLI does, but two defaults change where they are:

```bash
helm list -n app-services
helm list -n flux-system
```{{exec}}

The first list is empty. The record lives in the HelmRelease's namespace, `flux-system`, and the release name is `<targetNamespace>-<name>`: `app-services-voicemail` and `app-services-message-store`. Each reads `deployed`, and its `NAMESPACE` column names `app-services`, where the objects run.

```bash
helm history app-services-voicemail -n flux-system
```{{exec}}

The same history and revisions as in M17.

## The order gate

`Depends On` lists `message-store`. At the start of every pass, the helm-controller reads each listed HelmRelease. It continues only when each one exists and is `Ready True`. A HelmRelease lists other HelmReleases; a Kustomization lists other Kustomizations.

```bash
flux events --for HelmRelease/voicemail
```{{exec}}

`DependencyNotReady` events with the message `dependency 'flux-system/message-store' is not ready` come first. `InstallSucceeded` follows, after `message-store` turned ready.
