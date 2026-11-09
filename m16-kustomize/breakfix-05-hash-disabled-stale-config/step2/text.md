# Step 2 — Fix it and verify

A `kubectl rollout restart` would load 6000 today, and the next config change would fail the same way. Restore the hash instead, and handle the old ConfigMaps with `--prune`.

```bash
cd /root/edge-relay
sed -i '/^generatorOptions:/,/disableNameSuffixHash/d' overlays/prod/kustomization.yaml
kubectl kustomize overlays/prod | grep -n edge-relay-config
```{{exec}}

Both lines carry a hash again. Compare with the cluster before you apply:

```bash
kubectl diff -k overlays/prod
```{{exec}}

The diff adds a hashed ConfigMap and changes the Deployment's `configMapRef` name. That changed line starts the rollout.

```bash
kubectl apply -k overlays/prod --prune -l app=edge-relay
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

The output ends with `configmap/edge-relay-config pruned`: the unhashed ConfigMap left the render, so `--prune` deleted it. The `Deprecated:` warning concerns cluster-scoped objects and does not affect this prune.

## Verify

```bash
kubectl exec -n edge deploy/edge-relay -- printenv MAX_SESSIONS
kubectl rollout history deployment/edge-relay -n edge
```{{exec}}

6000, and a second revision. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m16-kustomize/ANSWER-KEY.md).
