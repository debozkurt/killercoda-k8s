# Step 2 — The render pipeline

`helm install` does three things in order: **merge** values, **render** templates into manifests, **apply** the result and record it as a release. This step makes that pipeline visible.

## Render client-side with `helm template`

`helm template` runs the merge + render locally and prints the manifests. Nothing touches the cluster:

```bash
helm template voicemail /root/voicemail \
  --namespace app-services \
  --set replicaCount=2 \
  --set config.sipRealm=polyphone.example | head -40
```{{exec}}

You get a plain Deployment and Service — every `{{ .Values.* }}` hole filled in. This is the single most useful Helm debugging command: it shows exactly what a set of values *would* produce, before you apply anything.

## See what's actually live with `helm get manifest`

`helm get manifest` prints the manifests Helm applied for the live release (read back from what Helm stored, not re-rendered):

```bash
helm get manifest voicemail -n app-services | head -40
```{{exec}}

For a release that hasn't drifted, this matches the `helm template` output above. When you're debugging "is the cluster running what I think it is," this is the answer — the recorded truth for revision 1.

## The relationship

```text
values.yaml (defaults)  ─┐
-f file / --set overrides ├─► MERGE ─► RENDER templates ─► MANIFESTS ─► apply + record release
chart templates ─────────┘
```

`helm template` = merge + render (offline). `helm get manifest` = the manifests of the live release. `kubectl get` = the objects those manifests became. Three views of the same pipeline.

## Confirm the rendered value landed

```bash
kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}{"\n"}'
```{{exec}}

`2` — the `replicaCount` the release was installed with, rendered into the Deployment's `spec.replicas`.

## Verify

```bash
helm get manifest voicemail -n app-services | grep -E "kind:|replicas:"
```{{exec}}

You should see `kind: Deployment` / `replicas: 2` and `kind: Service`. Move on to step 3.
