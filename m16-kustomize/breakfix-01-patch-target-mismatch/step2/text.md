# Step 2 — Fix it and verify

Point the patch at the name the base carries. The base name is the established one, so the patch is the side that drifted.

```bash
cd /root/edge-relay
sed -i 's/name: edge-relayer/name: edge-relay/' overlays/prod/replicas-patch.yaml
kubectl kustomize overlays/prod | grep -n replicas
```{{exec}}

The build prints manifests again, and the Deployment reads `replicas: 3`.

```bash
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

## Verify

```bash
kubectl get deploy edge-relay -n edge
```{{exec}}

`READY` reads 3/3. In a real repository, commit the fix: a GitOps controller renders the committed overlay, and it would undo a change made only on disk. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m16-kustomize/ANSWER-KEY.md).
