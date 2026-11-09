# Step 1 — Find why the drift stays

In the baseline, one pass of `apps` reverted a hand scale. Here the scale has lasted for hours. Read the pipeline in order.

## Confirm the drift

```bash
kubectl get deploy dialplan -n app-services
grep replicas /root/polyphone-config/apps/dialplan.yaml
```{{exec}}

The Deployment runs 5 replicas. Git declares 2.

## Read the source

```bash
flux get sources git
git -C /root/polyphone-config log --oneline -1
```{{exec}}

`READY True`, and the revision hash matches the newest commit. The fetch stage works.

## Read the consumer

```bash
flux get kustomizations
```{{exec}}

`apps` reads `READY True` and `Applied revision: main@sha1:...`, the same hash as the source. A glance says the pipeline is healthy. Now read the `SUSPENDED` column: `True`.

```bash
kubectl describe kustomization apps -n flux-system
```{{exec}}

Under `Spec`, `Suspend: true`. A suspended Kustomization skips every pass: no drift correction, no new revision, no prune. Its conditions are frozen at its last pass, which succeeded before the suspend.

## Prove that nothing runs

```bash
flux reconcile kustomization apps
```{{exec}}

The CLI refuses: `resource is suspended`. Nothing in the cluster will revert the drift until the suspend is lifted.
