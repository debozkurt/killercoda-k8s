# Step 2 — The Kustomization

A Flux **`Kustomization`** is a **consumer**: it reads the source's artifact, builds a `path` with Kustomize (the engine behind `kubectl apply -k` in M16) and applies the result. It is a different object from the `kustomization.yaml` file it builds.

## Read the consumer

```bash
flux get kustomizations
```{{exec}}

`apps` is `READY True`, and its message reads `Applied revision: main@sha1:...`. That revision equals the source revision from step 1, so the cluster runs the newest fetched commit.

```bash
kubectl describe kustomization apps -n flux-system
```{{exec}}

Under `Spec`, read `Path: ./apps`, `Prune: true`, `Target Namespace: app-services`, `Wait: true` and `Timeout: 1m`. `Wait` makes the controller report `Ready` only after the applied objects are healthy.

## See what it applied

```bash
cat /root/polyphone-config/apps/kustomization.yaml
flux tree kustomization apps
```{{exec}}

The file lists two resources, and the tree lists the same two objects: the `dialplan` Deployment and the `dialplan-routes` ConfigMap. That tree is the **inventory**, the list Flux prunes against.

```bash
kubectl get deploy,configmap -n app-services -l app=dialplan
```{{exec}}

Both objects run in `app-services`. The manifests in git name no namespace; `targetNamespace` put them there.

```bash
grep replicas /root/polyphone-config/apps/dialplan.yaml
```{{exec}}

`replicas: 2`. Step 3 changes that number in the cluster.
