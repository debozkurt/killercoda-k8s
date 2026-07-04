# Step 2 — Fix the stale variable and verify

The region overlay owns `REGION` and its copy is stale. Set it to this region's own identity:

```bash
cd /root/fleet
sed -i 's/REGION=us-east-1/REGION=eu-central-1/' regions/eu-central-1/kustomization.yaml
grep REGION regions/eu-central-1/kustomization.yaml
```{{exec}}

`us-east-1` appears only on that one stale literal in this file, so the substitution is precise. Or edit it by hand:

```bash
# regions/eu-central-1/kustomization.yaml
#   - REGION=us-east-1   ->   - REGION=eu-central-1
```

Fix it once, in the owning layer, and *every* cluster in `eu-central-1` inherits the correction — that's the point of one home per variable.

## Render before you apply

Confirm the composed cluster now reports its own region:

```bash
kubectl kustomize clusters/prod-eu-central-1 | grep -E 'REGION|region:'
```{{exec}}

Both read `eu-central-1` now. Push it:

```bash
kubectl apply -k clusters/prod-eu-central-1
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

The `REGION` change altered the ConfigMap contents, so its hash changed, so the Deployment rolled — the M16 hash contract, still working across three layers.

## Verify

Read the region the live Pod is actually running with:

```bash
REF=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')
kubectl get configmap "$REF" -n edge -o jsonpath='REGION={.data.REGION}{"\n"}'
```{{exec}}

`REGION=eu-central-1` — the cluster reports its own region. One line in the owning layer; the diagnosis was tracing a wrong value to the single file that produces it. For the full write-up see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
