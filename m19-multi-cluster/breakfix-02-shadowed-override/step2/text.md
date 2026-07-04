# Step 2 — Remove the shadow and verify

The region owns capacity now, and it's correct at `8000`. The leftover per-cluster override in the leaf is what shadows it. Remove it so the region's value flows through:

```bash
cd /root/fleet
sed -i '/^# Leftover/,$d' clusters/prod-us-east-1/kustomization.yaml
cat clusters/prod-us-east-1/kustomization.yaml
```{{exec}}

That deletes the leftover comment and the `configMapGenerator` block below it. Or edit by hand — delete the trailing block:

```bash
# clusters/prod-us-east-1/kustomization.yaml — delete these lines:
#   configMapGenerator:
#     - name: edge-relay-config
#       behavior: merge
#       literals:
#         - MAX_SESSIONS=5000
```

The leaf keeps its legitimate per-cluster settings (tier, replicas) and stops overriding a value the region owns. (If prod genuinely needed a different ceiling, the value would belong here on purpose — but the standard is regional, so the shadow is the bug.)

## Render before you apply

Confirm the cluster now inherits the regional standard:

```bash
kubectl kustomize clusters/prod-us-east-1 | grep MAX_SESSIONS
```{{exec}}

`8000` — the region's value, no longer shadowed. Push it:

```bash
kubectl apply -k clusters/prod-us-east-1
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

## Verify

Read the ceiling the live Pod is running with:

```bash
REF=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')
kubectl get configmap "$REF" -n edge -o jsonpath='MAX_SESSIONS={.data.MAX_SESSIONS}{"\n"}'
```{{exec}}

`MAX_SESSIONS=8000` — the region standard reaches the cluster. The fix was deleting a leftover; the diagnosis was tracing the field up its path and seeing that a later layer, not the one you'd edit, was the winner. For the full write-up see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
