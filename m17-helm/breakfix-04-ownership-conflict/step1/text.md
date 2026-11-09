# Step 1 — A clean render that will not install

## Look for a release and objects

```bash
helm list -n app-services
kubectl get deploy,svc -n app-services -l app=voicemail
```{{exec}}

No release and no Deployment, but a Service named `voicemail` exists. Note its `CLUSTER-IP`.

## Run the install again

```bash
helm install voicemail /root/voicemail --namespace app-services \
  --set replicaCount=2 --set config.sipRealm=polyphone.example
```{{exec}}

The error reads `Service "voicemail" in namespace "app-services" exists and cannot be imported into the current release: invalid ownership metadata`. It then lists the missing label and both missing annotations.

## Rule out the render

```bash
helm template voicemail /root/voicemail \
  --set replicaCount=2 --set config.sipRealm=polyphone.example | head -20
```{{exec}}

The render is clean. This is an apply-stage failure: the cluster holds an object that the release wants to create.

## Compare the object with a Helm-owned one

```bash
kubectl describe service voicemail -n app-services | head -8
```{{exec}}

`Labels:` has only `app=voicemail`, and `Annotations:` reads `<none>`. (`describe` hides the `kubectl.kubernetes.io/last-applied-configuration` annotation that `kubectl apply` writes.) A Helm-owned object carries `app.kubernetes.io/managed-by=Helm` and the annotations `meta.helm.sh/release-name` and `meta.helm.sh/release-namespace`. Helm adopts an existing object only when that metadata names this release.
