# Step 1 — Diagnose the stalled pod

The container never ran, so logs are empty. The status and the events carry the whole story.

## Read the status — and notice what it isn't

```bash
kubectl get pods -n analytics
```{{exec}}

`metrics-aggregator` is not `Running`, and its status is **`ErrImageNeverPull`** — not the `ImagePullBackOff` you'd see for a failed pull. That word *Never* is the tell: the kubelet was told not to pull, found nothing cached, and gave up. No registry was ever contacted.

## Confirm from the events

```bash
kubectl describe pod -n analytics -l app=metrics-aggregator | sed -n '/Events/,$p'
```{{exec}}

The event spells it out:

```text
Container image "nginx:1.27" is not present with pull policy of Never
```

Compare this to a real pull failure: there's no `Pulling`, no `Failed to pull`, no `Back-off pulling`. The kubelet never tried — because the pod spec forbade it.

## Find the two fields that caused it

`ErrImageNeverPull` is always the same pair: `imagePullPolicy: Never` plus an image that isn't cached on the node. Read both:

```bash
kubectl get deploy metrics-aggregator -n analytics \
  -o jsonpath='image={.spec.template.spec.containers[0].image}  policy={.spec.template.spec.containers[0].imagePullPolicy}{"\n"}'
```{{exec}}

You'll see `image=nginx:1.27  policy=Never`. The fleet only ever pulled `nginx:1.25`, so `nginx:1.27` was never cached on this node — and `Never` means the kubelet won't fetch it. Either half alone is harmless (`Never` is fine for a *cached* image; `nginx:1.27` is fine with a *normal* policy). It's the combination that stalls the pod. On to the fix.
