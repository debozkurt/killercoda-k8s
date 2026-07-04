# Step 1 — The fleet layout

The repo describes a whole fleet from one base. Read the shape first:

```bash
cd /root/fleet
find . -name kustomization.yaml | sort
```{{exec}}

Three layers: one `base/`, two `regions/`, four `clusters/`. Each cluster is a leaf built by composing a region overlay, which composes the base.

Follow the chain for one cluster. A leaf points its `resources:` at a region:

```bash
cat clusters/prod-us-east-1/kustomization.yaml
```{{exec}}

`resources: [../../regions/us-east-1]` — the leaf pins its **tier** (`tier: prod`) and **replicas** (a patch), and composes the region. Now the region it points at:

```bash
cat regions/us-east-1/kustomization.yaml
```{{exec}}

`resources: [../../base]` — the region owns region-scoped values (`REGION`, the `MAX_SESSIONS` capacity standard) and composes the base. So `prod-us-east-1` reads as a path: **base → regions/us-east-1 → this leaf**.

## Render the composed cluster

`kubectl kustomize clusters/<cluster>` folds that whole path into the exact manifests the cluster receives. It touches no cluster — it's the trace tool you'll live in this module:

```bash
kubectl kustomize clusters/prod-us-east-1
```{{exec}}

Read it top to bottom. The rendered Deployment carries `replicas: 3` (the leaf's patch), `tier: prod` and `region: us-east-1` labels, and its `envFrom` references a hash-suffixed `edge-relay-config-<hash>` ConfigMap whose data was assembled from all three layers. One base, evaluated for one cluster. Step 2 traces where each of those values came from.
