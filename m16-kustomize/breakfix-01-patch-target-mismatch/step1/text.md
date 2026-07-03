# Step 1 — Read the build error

First confirm the symptom. The `edge` namespace runs the fleet's `sbc-edge` and `pstn-gateway`, but `edge-relay` should be here too:

```bash
kubectl get deploy -n edge
kubectl get pods -n edge -l app=edge-relay
```{{exec}}

No `edge-relay` Deployment, no Pods. There's nothing in the cluster to diagnose — which is the tell. When an `apply -k` produces *nothing*, suspect the build, not the cluster.

## Render the overlay yourself

Run the same build the deploy job runs. `apply -k` calls `kustomize build` first; do just that half and read what it says:

```bash
cd /root/edge-relay
kubectl kustomize overlays/prod
```{{exec}}

It doesn't print manifests — it prints an error:

```text
Error: no resource matches strategic merge patch "Deployment.v1.apps/edge-relayer.[noNs]":
no matches for Id Deployment.v1.apps/edge-relayer.[noNs]; failed to find unique target for patch ...
```

Read it literally. Kustomize has a patch whose target is `Deployment/edge-relayer`, and **no resource with that identity exists** in what it assembled. A `patches:` entry isn't optional — if its target can't be found, the whole build fails. (This is deliberate: a patch that silently matched nothing would be a config change that quietly does nothing.)

## Find the mismatch

Two facts to line up: what the patch targets, and what the base actually names. The prod overlay lists its patch:

```bash
grep -A2 'patches:' overlays/prod/kustomization.yaml
cat overlays/prod/replicas-patch.yaml
```{{exec}}

The patch file is a Deployment named `edge-relayer`. Now the name the base carries:

```bash
kubectl kustomize base | grep -E '^kind:|  name:'
```{{exec}}

The base Deployment is `edge-relay`. The patch targets `edge-relayer` — a name nothing carries (someone renamed the base, or fat-fingered the patch). A `patches:` entry with a `path:` and no explicit `target:` selects by the patch's own `apiVersion`/`kind`/`metadata.name`, so that `metadata.name` has to match a real resource. It doesn't. On to the fix.
