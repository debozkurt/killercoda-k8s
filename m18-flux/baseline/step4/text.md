# Step 4 — HelmRelease and dependencies

helm-controller runs Helm — the same install/upgrade model from M17 — but driven by a `HelmRelease` object instead of a `helm` command. The chart comes from a source; here it's a directory inside the same git repo, so no external Helm repository is needed.

## Read the release

```bash
flux get helmreleases
```{{exec}}

Two releases — `message-store` and `voicemail` — both `READY True`, each with a message about its installed revision. helm-controller rendered `./charts/voicemail` and `./charts/message-store` and installed them.

```bash
kubectl get helmrelease voicemail -n flux-system -o yaml | grep -A10 '^spec:'
```{{exec}}

`chart.spec.chart: ./charts/voicemail` with `sourceRef.kind: GitRepository` — the chart is pulled from the git source, not a Helm repo. `values.replicaCount: 2` is the input; `targetNamespace: app-services` is where it installs.

## It's a real Helm release

helm-controller uses Helm's own release storage, so the M17 commands still work:

```bash
helm list -n app-services
```{{exec}}

`voicemail` and `message-store`, both `deployed`. And the workload is ordinary:

```bash
kubectl get deploy voicemail -n app-services
```{{exec}}

`READY 2/2`.

## The dependency that ordered it

```bash
kubectl get helmrelease voicemail -n flux-system -o jsonpath='{.spec.dependsOn}{"\n"}'
```{{exec}}

`[{"name":"message-store"}]`. The release `dependsOn` the `message-store` HelmRelease — helm-controller waited until `message-store` was `Ready` before installing `voicemail`. `dependsOn` references other HelmReleases (same kind), so this is how you order an app release behind a release it needs — here its backing store.

## Verify

```bash
kubectl get helmrelease voicemail -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}'
kubectl get deploy voicemail -n app-services -o jsonpath='{.status.readyReplicas}{"\n"}'
```{{exec}}

`True` and `2`. You've seen the whole pipeline: source → Kustomization → HelmRelease, with drift correction and dependency ordering. See `finish.md`.
