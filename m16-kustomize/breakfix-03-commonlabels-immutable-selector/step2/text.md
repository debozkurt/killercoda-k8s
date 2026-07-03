# Step 2 — Move labels off the selector and verify

You want `tier: prod` as a label on the objects, just not in the Deployment's selector. The `labels:` transformer with `includeSelectors: false` does exactly that — it's what the lab overlay already uses, and it's the modern replacement for `commonLabels`. Swap the prod overlay's transformer.

In `overlays/prod/kustomization.yaml`, replace:

```yaml
commonLabels:
  tier: prod
```

with:

```yaml
labels:
  - pairs: { tier: prod }
    includeSelectors: false
```

Run this to make the swap in place:

```bash
cd /root/edge-relay
awk '
  /^commonLabels:/ { print "labels:"; print "  - pairs: { tier: prod }"; print "    includeSelectors: false"; skip=1; next }
  skip==1 && /^[[:space:]]+tier: prod[[:space:]]*$/ { skip=0; next }
  { print }
' overlays/prod/kustomization.yaml > /tmp/prod.yaml && mv /tmp/prod.yaml overlays/prod/kustomization.yaml
grep -A2 'labels:' overlays/prod/kustomization.yaml | head -3
```{{exec}}

## Confirm the selector is clean before applying

The render's selector should be back to `{app: edge-relay}`, with `tier: prod` only on metadata:

```bash
kubectl kustomize overlays/prod | grep -A2 'matchLabels'
```{{exec}}

`tier: prod` is gone from the selector. Because the selector now matches the live Deployment's selector, the apply is an ordinary update — no immutable-field change:

```bash
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

## Verify

```bash
kubectl get deploy edge-relay -n edge -o wide
kubectl get deploy edge-relay -n edge \
  -o jsonpath='selector={.spec.selector.matchLabels}  meta-tier={.metadata.labels.tier}{"\n"}'
```{{exec}}

`READY 3/3` on `nginx:1.27` — the prod promotion landed. The selector is still `{app: edge-relay}` (untouched), and `tier: prod` is present as a metadata label. You got the label you wanted without touching the field you're not allowed to change. For the full write-up see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
