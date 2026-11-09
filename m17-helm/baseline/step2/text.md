# Step 2 — Render and compare

An install has three stages: **render** the templates with the merged values, **record** a revision, **apply** the manifests. This step shows the render and the record side by side.

## Render on your machine

`helm template` merges values and renders the chart. It sends nothing to the cluster.

```bash
helm template voicemail /root/voicemail \
  --namespace app-services \
  --set replicaCount=2 \
  --set config.sipRealm=polyphone.example | head -40
```{{exec}}

Every placeholder is now a literal value. Look for `replicas: 2` in the Deployment.

## Read what Helm applied

`helm get manifest` prints the manifest that Helm stored for the current revision. Helm does not render it again.

```bash
helm get manifest voicemail -n app-services | head -40
```{{exec}}

The two outputs match, because the release was installed with the same values. The chart on disk can change after an install, so `helm get manifest` is the answer to "what is the cluster supposed to run?"

```text
values + templates --helm template--> manifest --apply--> live objects
                                         |
                                   helm get manifest (stored per revision)
```

```bash
kubectl get deployment voicemail -n app-services
```{{exec}}

`READY` reads 2/2: the live object matches the stored manifest.
