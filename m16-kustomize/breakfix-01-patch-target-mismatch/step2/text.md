# Step 2 — Fix the patch target and verify

The base Deployment is `edge-relay`; the patch targets `edge-relayer`. Point the patch at the name that exists:

```bash
cd /root/edge-relay
sed -i 's/name: edge-relayer/name: edge-relay/' overlays/prod/replicas-patch.yaml
cat overlays/prod/replicas-patch.yaml
```{{exec}}

Or edit it by hand:

```bash
# overlays/prod/replicas-patch.yaml
# metadata:
#   name: edge-relayer   ->   name: edge-relay
```

(The mirror-image fix is valid too: if the *base* was the thing that got renamed to `edge-relayer` and everything else expects that, you'd rename the base instead. Fix whichever side is wrong — here the base name `edge-relay` is the established one.)

## Render before you apply

Confirm the build is clean now — this is the habit that would have caught it in review:

```bash
kubectl kustomize overlays/prod | grep -E 'kind: Deployment|replicas:'
```{{exec}}

It prints manifests instead of an error, and the Deployment shows `replicas: 3` — the patch found its target and applied. Now push it:

```bash
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

## Verify

```bash
kubectl get deploy edge-relay -n edge
```{{exec}}

`READY 3/3` — edge-relay exists and the prod replica count landed. The fix was one line in a patch file; the diagnosis was reading a build error instead of poking at a cluster that had nothing to show. For the full write-up see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
