# Step 2 — Fix it and verify

The pod needs the image, and `Never` forbids fetching it. The right fix is the one that matches intent: this image *should* come from a registry, so let the kubelet pull it.

## Let the kubelet pull

Change `imagePullPolicy` from `Never` to `IfNotPresent` (pull only if not cached) — the normal default for a pinned tag. A Deployment is mutable, so edit in place and it rolls a new pod:

```bash
kubectl patch deployment metrics-aggregator -n analytics \
  --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]'
```{{exec}}

Or by hand:

```bash
kubectl edit deployment metrics-aggregator -n analytics
# change  imagePullPolicy: Never  to  IfNotPresent  (or delete the line; the default for a non-:latest tag is IfNotPresent)
```

The kubelet now contacts Docker Hub, pulls `nginx:1.27`, and the pod starts.

## Know the other valid fix

If this were genuinely an air-gapped node where pulling isn't allowed, the fix is the opposite: keep `Never` and make sure the image is **pre-loaded** onto the node (side-loaded via `ctr image import`, or pinned to a tag that's already cached like `nginx:1.25`). `Never` isn't wrong — it's a deliberate choice that requires the image to already be present. The bug here was pairing it with an uncached tag.

## Verify

```bash
kubectl get pods -n analytics
kubectl get deploy metrics-aggregator -n analytics \
  -o jsonpath='policy={.spec.template.spec.containers[0].imagePullPolicy}{"\n"}'
```{{exec}}

`metrics-aggregator` is `Running` `1/1`, and the policy is no longer `Never`. The pull happened because you let it.

For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
