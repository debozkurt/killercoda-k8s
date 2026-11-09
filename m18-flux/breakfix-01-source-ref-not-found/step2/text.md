# Step 2 — Fix it and verify

The `GitRepository` must name a branch that exists. In this cluster the Flux objects were applied by hand, so the fix is a patch on the live object.

## Point the source at main

```bash
kubectl patch gitrepository polyphone-config -n flux-system \
  --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux reconcile source git polyphone-config
```{{exec}}

`fetched revision main@sha1:...`. The source stored its first artifact.

## Watch the consumers follow

A new artifact triggers each consumer at once, without waiting for its interval. The HelmReleases need about a minute: `message-store` installs first, and `voicemail` waits for it.

```bash
flux get kustomizations
flux get helmreleases
kubectl get deploy -n app-services
```{{exec}}

`apps` reads `Applied revision: main@sha1:...`, with the same hash as the source. Run the commands again until both HelmReleases read `Helm install succeeded` and the three Deployments are ready.

## Verify

```bash
flux get all
```{{exec}}

Every object is `READY True`. In a bootstrapped fleet, the `GitRepository` manifest lives in git too, and the durable fix is a reviewed commit to that manifest.
