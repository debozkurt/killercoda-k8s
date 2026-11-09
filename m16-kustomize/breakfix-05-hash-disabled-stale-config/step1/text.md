# Step 1 — Diagnose

## What the containers hold

```bash
kubectl exec -n edge deploy/edge-relay -- printenv MAX_SESSIONS
```{{exec}}

5000. The container's environment still holds the old value.

## What the ConfigMap holds

```bash
kubectl get cm -n edge -l app=edge-relay
```{{exec}}

One ConfigMap, named `edge-relay-config`, with no hash suffix.

```bash
kubectl describe cm edge-relay-config -n edge
```{{exec}}

Under `Data`, the line below `MAX_SESSIONS:` and its `----` reads 6000. The ConfigMap has the new value, and the containers have the old one.

## Why nothing restarted

A container reads `envFrom` values once, when it starts. An update to the ConfigMap changes no Pod.

```bash
kubectl rollout history deployment/edge-relay -n edge
kubectl get pods -n edge -l app=edge-relay
```{{exec}}

One revision: the Deployment never rolled after its first apply, and the Pods never restarted. The Pod template never changed. The template names the ConfigMap, and the name stayed the same.

## Why the name stayed the same

```bash
cd /root/edge-relay
kubectl kustomize overlays/prod | grep -n edge-relay-config
```{{exec}}

Both lines, the ConfigMap and the `configMapRef`, read the bare `edge-relay-config`. In the baseline both carried a hash.

```bash
cat overlays/prod/kustomization.yaml
```{{exec}}

`generatorOptions: disableNameSuffixHash: true`. That is last month's change. It stopped the old ConfigMaps from accumulating, and it also removed the mechanism that turns a config change into a rollout.
