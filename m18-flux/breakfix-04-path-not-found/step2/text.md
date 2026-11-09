# Step 2 — Fix it and verify

Two fixes are correct: move the files back in git, or point the `Kustomization` at the new path. The restructure was intended, so update the path. In this cluster the Flux objects were applied by hand, so patch the live object.

## Point the build at the new path

```bash
kubectl patch kustomization apps -n flux-system \
  --type=merge -p '{"spec":{"path":"./deploy/apps"}}'
flux reconcile kustomization apps
```{{exec}}

`applied revision main@sha1:...` with the restructure hash.

## Verify

```bash
flux get kustomizations
kubectl get deploy dialplan -n app-services
flux tree kustomization apps
```{{exec}}

`apps` is `READY True`, and its revision equals the source revision. `dialplan` runs 3 replicas. The inventory still holds the same two objects: the files moved, and the objects did not, so prune deleted nothing.
