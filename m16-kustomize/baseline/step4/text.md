# Step 4 — The hash contract

A container reads `envFrom` values once, when it starts. An in-place ConfigMap edit changes no Pod template, so nothing restarts. The hash closes that gap: new data gives a new name, the new name changes the Pod template, and the template change starts a rollout.

Raise the session limit in the prod overlay from 5000 to 6000:

```bash
sed -i 's/MAX_SESSIONS=5000/MAX_SESSIONS=6000/' overlays/prod/kustomization.yaml
kubectl diff -k overlays/prod
```{{exec}}

Read the diff, and skip the `last-applied-configuration` and `generation` lines. It shows a new ConfigMap with `MAX_SESSIONS: "6000"`. In the Deployment, the `configMapRef` name changes from the old hash to the new one. That one changed line rolls the Deployment. `kubectl diff` exits 1, because a difference exists.

```bash
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
kubectl get rs -n edge -l app=edge-relay
```{{exec}}

Two ReplicaSets: the old one scaled to 0, and a new one with 3 Pods. Confirm that a new container reads the new value:

```bash
kubectl exec -n edge deploy/edge-relay -- printenv MAX_SESSIONS
```{{exec}}

It prints 6000.

## The old ConfigMap stays

```bash
kubectl get cm -n edge -l app=edge-relay
```{{exec}}

Two ConfigMaps. `apply` creates and updates objects and never deletes one. `--prune` deletes objects that carry the label, were created by `apply`, and are no longer in the render:

```bash
kubectl apply -k overlays/prod --prune -l app=edge-relay
kubectl get cm -n edge -l app=edge-relay
```{{exec}}

The output ends with the old ConfigMap's `pruned` line, and one ConfigMap remains. The `Deprecated:` warning above it concerns cluster-scoped objects and does not affect this prune. (In production, a GitOps controller does this garbage collection; see M18.)
