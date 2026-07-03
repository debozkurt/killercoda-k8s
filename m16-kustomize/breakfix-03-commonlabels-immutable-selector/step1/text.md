# Step 1 — Read the rejected apply

First confirm which spec is live. edge-relay is running, but check the replica count against what prod should be (3):

```bash
kubectl get deploy edge-relay -n edge
```{{exec}}

`READY 1/1` — that's the lab spec (one replica). The prod promotion never applied. Reproduce it in the foreground and read what the API server says:

```bash
cd /root/edge-relay
kubectl apply -k overlays/prod
```{{exec}}

```text
The Deployment "edge-relay" is invalid: spec.selector: Invalid value:
  v1.LabelSelector{MatchLabels:map[string]string{"app":"edge-relay", "tier":"prod"}, ...}:
  field is immutable
```

The build was fine — this is not a `kustomize` error, it's an API-server error. It's refusing to change `spec.selector`. A Deployment's selector is **immutable after creation**: it's the identity link between the Deployment and its Pods/ReplicaSets, and changing it would orphan everything the Deployment already owns.

## Why is a promotion touching the selector?

A replica bump and an image pin shouldn't go near the selector. Compare what's live to what the overlay renders. Live selector:

```bash
kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.selector.matchLabels}{"\n"}'
```{{exec}}

`{"app":"edge-relay"}`. Now the rendered selector the apply tried to push:

```bash
kubectl kustomize overlays/prod | grep -A2 'matchLabels'
```{{exec}}

The render's selector is `{app: edge-relay, tier: prod}` — the overlay is adding `tier: prod` *into the selector*, not just onto metadata. That's the change the API server refuses.

## Find the transformer

A `tier` label that lands in selectors, metadata, *and* templates is the signature of `commonLabels`. Look at the prod overlay:

```bash
grep -A1 'commonLabels' overlays/prod/kustomization.yaml
```{{exec}}

There it is. `commonLabels` applies its labels to **every** selector in the build — including the Deployment's immutable one. On a fresh namespace that's harmless (the selector is being set for the first time). Promoting onto an already-running Deployment, it's fatal. The lab overlay avoided this by using the `labels:` transformer with `includeSelectors: false`; prod used `commonLabels` and got bitten. On to the fix.
