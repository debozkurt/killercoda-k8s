# Step 1 — Diagnose

## The normal loop works this time

Apply succeeded, so objects exist.

```bash
kubectl get pods -n edge -l app=edge-relay
```{{exec}}

Three Pods in `CreateContainerConfigError`. The kubelet cannot assemble a container's configuration. The events name the reason:

```bash
kubectl events -n edge --types=Warning
```{{exec}}

The repeated `edge-relay` lines, marked `(xN over ...)`, read `Error: configmap "edge-relay-conf" not found`. A single `failed to sync configmap cache` line before them is the kubelet's first attempt. Compare with what exists:

```bash
kubectl get cm -n edge -l app=edge-relay
```{{exec}}

One ConfigMap, `edge-relay-config-` plus a hash. Nothing is named `edge-relay-conf`.

## Read the render

The cluster shows the result. The render shows why.

```bash
cd /root/edge-relay
kubectl kustomize overlays/prod | grep -n edge-relay-conf
```{{exec}}

Two lines. The ConfigMap's `name:` carries the hash. The Deployment's `configMapRef` reads the bare `edge-relay-conf`. In the baseline, Kustomize rewrote this reference to the hashed name. Here it did not.

## Line up the names

```bash
grep -n edge-relay-conf base/deployment.yaml base/kustomization.yaml
```{{exec}}

The Deployment references `edge-relay-conf`. The generator is named `edge-relay-config`. Kustomize rewrites a reference only when it names the generator exactly, so it left this one alone. Build and apply both succeeded, and the reference points at a ConfigMap that nothing creates.
