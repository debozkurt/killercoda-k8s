# Step 1 — An install that left nothing

Check what the failed install left behind, then make the failure show itself.

## Look for a release and objects

```bash
helm list -n app-services
kubectl get deploy,svc -n app-services -l app=voicemail
kubectl get secret -n app-services -l owner=helm
```{{exec}}

In Helm 4, `helm list` shows releases in every status, including `failed` and `pending-install`. It shows no `voicemail` row. There is no Deployment, no Service and no release Secret. The install stopped before Helm wrote anything to the cluster.

## Run the install again

```bash
helm install voicemail /root/voicemail --namespace app-services --set replicaCount=2
```{{exec}}

```text
Error: INSTALLATION FAILED: execution error at (voicemail/templates/deployment.yaml:25:24):
voicemail: .Values.config.sipRealm is required (the SIP realm to register under)
```

`execution error at (<template>:<line>:<col>)` is a render error. The message after it is the chart author's text from the `required` function. Helm renders before it creates the release record, so a render error leaves no trace in the cluster.

## Reproduce it offline

```bash
helm template voicemail /root/voicemail --set replicaCount=2
```{{exec}}

The same error, with no cluster involved. Iterate on values with `helm template` until the render is clean.

```bash
helm show values /root/voicemail
```{{exec}}

The chart ships `sipRealm: ""`. The value has no safe default, so each install must supply it.
