# Step 2 — Fix it and verify

Keep `tier: prod` as a label, and keep it out of the selector. The `labels:` transformer does that with `includeSelectors: false`, which is what the lab overlay uses. Do not delete the Deployment to force the label in: that is an outage.

Replace the two `commonLabels` lines in `overlays/prod/kustomization.yaml`:

```bash
cd /root/edge-relay
sed -i 's/^commonLabels:/labels:\n  - pairs: { tier: prod }\n    includeSelectors: false/; /^  tier: prod$/d' \
  overlays/prod/kustomization.yaml
cat overlays/prod/kustomization.yaml
```{{exec}}

The overlay now has a `labels:` block in place of `commonLabels`. Ask the API server again:

```bash
kubectl diff -k overlays/prod
```{{exec}}

No error this time. The Deployment diff shows the prod changes: `replicas`, the image tag, the `tier` label, the `affinity:` block, and the `configMapRef` hash. It shows no selector change. The Service diff removes `tier: prod` from its selector.

```bash
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

## Verify

```bash
kubectl get deploy edge-relay -n edge -o wide --show-labels
```{{exec}}

`READY` 3/3 on nginx:1.27, `SELECTOR` still `app=edge-relay`, and `tier=prod` in the labels.

```bash
kubectl describe svc edge-relay -n edge
```{{exec}}

`Selector:` reads `app=edge-relay` again, and `Endpoints:` lists three Pod addresses. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m16-kustomize/ANSWER-KEY.md).
