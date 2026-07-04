# Step 1 — Trace the wrong value to its layer

First confirm the workload is healthy — this isn't a crash, it's a wrong value:

```bash
kubectl get pods -n edge -l app=edge-relay
```{{exec}}

`Running`. Nothing to `describe`; the bug is in what the Pod was *configured with*, not whether it started. Read the region the cluster actually renders:

```bash
cd /root/fleet
kubectl kustomize clusters/prod-eu-central-1 | grep -E 'REGION|region:'
```{{exec}}

The `region:` label says `eu-central-1`, but the `REGION` config value renders `us-east-1`. That mismatch is the whole bug — a downstream service reads `REGION` from config, so calls get tagged `us-east-1`.

## Trace it up the layer path

`REGION` is a cluster variable. Which layer owns it? Grep every layer in this cluster's path — base, its region, its leaf:

```bash
grep -rn REGION base regions/eu-central-1 clusters/prod-eu-central-1
```{{exec}}

Only one layer sets it: `regions/eu-central-1/kustomization.yaml`, and it says `REGION=us-east-1`. The base doesn't set `REGION`; the leaf doesn't either. The region overlay is the **owning layer**, and its copy is stale.

## Why it's stale

Read the region overlay:

```bash
cat regions/eu-central-1/kustomization.yaml
```{{exec}}

The `region:` label was updated to `eu-central-1`, but the `REGION` generator literal still reads `us-east-1` — a clone of `regions/us-east-1/` where one line got missed. Compare the two regions to see the drift:

```bash
diff regions/us-east-1/kustomization.yaml regions/eu-central-1/kustomization.yaml
```{{exec}}

They differ on the label and `MAX_SESSIONS` (correct — those are region-specific) but agree on `REGION=us-east-1` (wrong — the clone should have changed it). The value is stale in its owning layer. On to the fix.
