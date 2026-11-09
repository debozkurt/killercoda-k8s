# Step 2 — Fix it and verify

Point `dependsOn` at the HelmRelease that exists. The Flux objects in this cluster were applied by hand, so patch the live object.

## Correct the reference

```bash
kubectl patch helmrelease voicemail -n flux-system \
  --type=merge -p '{"spec":{"dependsOn":[{"name":"message-store"}]}}'
flux reconcile helmrelease voicemail
```{{exec}}

A spec change starts a pass at once. `message-store` is `Ready True`, so the gate opens, and the helm-controller installs the chart.

## Verify

```bash
flux get helmreleases
helm list -n flux-system
kubectl get deploy voicemail -n app-services
```{{exec}}

`voicemail` reads `Helm install succeeded`, the release `app-services-voicemail` is `deployed`, and the Deployment runs 2 replicas.
