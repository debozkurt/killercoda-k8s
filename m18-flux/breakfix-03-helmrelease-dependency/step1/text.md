# Step 1 — Find what holds the release

The source, `apps` and `message-store` are green. Start at the object that is not.

## Read the release

```bash
flux get helmreleases
```{{exec}}

`message-store` reads `Helm install succeeded`. `voicemail` is `READY False` with no revision, and its message begins `unable to get 'flux-system/message-cache' dependency`. The helm-controller stopped at the order gate, before it rendered the chart.

```bash
kubectl describe helmrelease voicemail -n flux-system
```{{exec}}

Under `Spec`, `Depends On` lists `Name: message-cache`. Under `Status`, the `Ready` condition has the reason `DependencyNotReady`, and the message ends with `helmreleases.helm.toolkit.fluxcd.io "message-cache" not found`.

## Read the message, not the reason

`DependencyNotReady` covers two cases, and the message tells them apart:

- `dependency '<ns>/<name>' is not ready`: the dependency exists and is red. Fix the dependency.
- `unable to get '<ns>/<name>' dependency: ... not found`: no object of that kind has that name. Fix the reference.

This release has the second case. `dependsOn` in a HelmRelease names other HelmReleases, so list those:

```bash
kubectl get helmreleases -n flux-system
```{{exec}}

`message-store` and `voicemail`. No `message-cache`: the reference kept the store's old name after the rename.

## Rule out the chart

```bash
helm template /root/polyphone-config/charts/voicemail
```{{exec}}

The chart renders a Service and a Deployment without an error. The chart was never the problem: the gate never opened.
