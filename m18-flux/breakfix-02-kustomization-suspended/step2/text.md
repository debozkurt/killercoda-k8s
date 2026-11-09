# Step 2 — Fix it and verify

Resume reconciliation. Do not scale `dialplan` back by hand: that hides the drift and leaves delivery off.

## Resume

```bash
flux resume kustomization apps
```{{exec}}

`flux resume` clears `spec.suspend` and waits for a pass. The pass applies the git manifest and takes the `replicas` field back.

```bash
kubectl get deploy dialplan -n app-services
flux get kustomizations
```{{exec}}

2 replicas, and `SUSPENDED False`.

## Prove that drift correction is back

```bash
kubectl scale deployment dialplan -n app-services --replicas=4
flux reconcile kustomization apps
kubectl get deploy dialplan -n app-services
```{{exec}}

Back to 2. If 5 replicas had been the right answer, the lasting fix would be a commit that sets `replicas: 5` in git, made before the resume.
