# Step 2 — Fix it and verify

Name the Deployment the patch must change:

```bash
cd /root/edge-relay
sed -i 's/name: relay }/name: edge-relay }/' overlays/prod/kustomization.yaml
kubectl kustomize overlays/prod | grep -n replicas
```{{exec}}

`replicas: 3`. Read the render before you apply: a selector patch gives no other signal that it matched.

```bash
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

## Verify

```bash
kubectl get deploy edge-relay -n edge
```{{exec}}

`READY` 3/3. In CI, assert the fields each overlay exists to set, such as `replicas: 3` for prod. Or use a patch file with no `target:` when you mean one resource: a missing resource then stops the build. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m16-kustomize/ANSWER-KEY.md).
