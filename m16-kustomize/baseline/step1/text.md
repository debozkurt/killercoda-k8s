# Step 1 — The base

A **kustomization** is a directory with a `kustomization.yaml` file. A **base** is a kustomization that other kustomizations build on.

```bash
cd /root/edge-relay
cat base/kustomization.yaml
```{{exec}}

Three fields do the work. `resources:` lists the raw manifests. `namespace: edge` is a **transformer**: it sets the namespace on every resource. `configMapGenerator` builds a ConfigMap from literals, so nobody writes that ConfigMap by hand.

## Render it

`kubectl kustomize <dir>` builds the kustomization and prints the result. It contacts no cluster.

```bash
kubectl kustomize base
```{{exec}}

The output is three objects: a ConfigMap, a Service, and a Deployment. Read the ConfigMap's `name:` line. It is not `edge-relay-config`. It is `edge-relay-config-` plus a hash of the ConfigMap's data.

Now find every line that carries that name:

```bash
kubectl kustomize base | grep -n edge-relay-config
```{{exec}}

Two lines match: the ConfigMap's own `name:`, and the `name:` under the Deployment's `configMapRef`. The Deployment file asks for the plain name:

```bash
grep -n -A1 configMapRef base/deployment.yaml
```{{exec}}

Kustomize rewrote the reference to the hashed name, because the reference names the generator exactly. The base has one replica and the base config everywhere. Everything that differs per environment lives in the overlays.
