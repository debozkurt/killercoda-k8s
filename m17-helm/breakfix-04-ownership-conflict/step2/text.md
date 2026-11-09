# Step 2 — Adopt the object and verify

Deleting the Service would let Helm create it, but its callers would lose it for a moment, and it would come back with a new ClusterIP. Adopt it instead: write the metadata that hands it to the release.

## Write the ownership metadata

```bash
kubectl label service voicemail -n app-services app.kubernetes.io/managed-by=Helm
kubectl annotate service voicemail -n app-services \
  meta.helm.sh/release-name=voicemail \
  meta.helm.sh/release-namespace=app-services
```{{exec}}

## Install

```bash
helm install voicemail /root/voicemail --namespace app-services \
  --set replicaCount=2 --set config.sipRealm=polyphone.example
```{{exec}}

`STATUS: deployed`. Helm adopted the Service and created the Deployment. `helm install --take-ownership` gets the same result in one command. It skips the ownership check, so first make sure that no other release owns the object.

## Verify

```bash
helm list -n app-services
kubectl get deploy,svc -n app-services -l app=voicemail
kubectl describe service voicemail -n app-services | grep 'Endpoints:'
```{{exec}}

The release is `deployed`, the Deployment reaches 2/2, and the Service keeps the `CLUSTER-IP` you noted in step 1. `Endpoints:` now lists two Pod addresses.

The error names one object at a time. In a real migration, expect one round of this fix for every object that existed before the chart.
