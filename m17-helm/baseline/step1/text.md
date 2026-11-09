# Step 1 — The chart and the release

A **chart** is a directory of templates plus default values. A **release** is one installed instance of a chart, identified by name and namespace.

## Read the chart

```bash
helm version --short
ls -R /root/voicemail
```{{exec}}

Helm is a client-side binary. It talks to the same API server as `kubectl`, and nothing Helm-specific runs in the cluster. The chart has `Chart.yaml` (name and version), `values.yaml` (defaults) and `templates/` (manifests with placeholders, plus `_helpers.tpl` for shared snippets).

```bash
cat /root/voicemail/values.yaml
```{{exec}}

Note the key paths: `replicaCount`, `image.tag`, `config.sipRealm`.

```bash
cat /root/voicemail/templates/deployment.yaml
```{{exec}}

Each `{{ .Values.<path> }}` is a Go template action. Helm replaces it at render time with the merged value at that exact path. `sipRealm` is wrapped in `required`, so a render without it stops with an error.

## Find the release

```bash
helm list -n app-services
```{{exec}}

One row: `voicemail`, `REVISION` 1, `STATUS` deployed, `CHART` voicemail-0.1.0.

```bash
kubectl get deploy,svc,pods -n app-services -l app=voicemail
```{{exec}}

The release produced ordinary objects: a Deployment with 2 Pods and a Service.

```bash
kubectl describe deployment voicemail -n app-services | head -12
```{{exec}}

Read the `Labels:` and `Annotations:` lines. Helm wrote `app.kubernetes.io/managed-by=Helm` and the two `meta.helm.sh/release-*` annotations. That metadata is how Helm recognizes an object it owns.
