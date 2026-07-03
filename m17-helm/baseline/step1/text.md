# Step 1 — The chart and the release

A **chart** is a directory of templates plus a default `values.yaml`. A **release** is one installed instance of a chart, tracked by name. Start by looking at both.

## Confirm Helm is installed

```bash
helm version --short
```{{exec}}

You should see a `v3.x` version string. Helm is a client-side binary — it talks to the same API server `kubectl` does; there is no server-side Helm component (that was Tiller, removed in Helm 3).

## Read the chart on disk

The `voicemail` chart lives at `/root/voicemail`:

```bash
ls -R /root/voicemail
```{{exec}}

Four pieces: `Chart.yaml` (metadata), `values.yaml` (defaults), and `templates/` (the manifests-with-holes plus a `_helpers.tpl` of shared snippets).

```bash
cat /root/voicemail/Chart.yaml
```{{exec}}

```bash
cat /root/voicemail/values.yaml
```{{exec}}

Note the keys: `replicaCount`, `image.repository`, `image.tag`, and `config.sipRealm`. Those are the exact key paths the templates read — a value set at any other path is ignored.

```bash
cat /root/voicemail/templates/deployment.yaml
```{{exec}}

This is a Deployment with `{{ .Values.replicaCount }}` where the replica count goes and `{{ .Values.image.tag }}` where the tag goes. The `{{ ... }}` are Go template actions filled in at render time. `sipRealm` is wrapped in `required` — render fails if it isn't supplied.

## See the live release

```bash
helm list -n app-services
```{{exec}}

One release: `voicemail`, `STATUS deployed`, `REVISION 1`, `CHART voicemail-0.1.0`. `helm list` shows what Helm manages; it does not list plain `kubectl apply`'d objects.

```bash
kubectl get deploy,svc,pods -n app-services -l app=voicemail
```{{exec}}

The release produced a Deployment (2 pods `Running`), a Service, and the pods behind it — ordinary Kubernetes objects. Helm rendered and applied them; the cluster doesn't know or care that Helm was involved.

## Verify

```bash
helm status voicemail -n app-services | head -5
```{{exec}}

`STATUS: deployed`. Move on to step 2.
