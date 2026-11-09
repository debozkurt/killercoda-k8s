# Step 3 — Drift correction

**Drift** is a difference between a live object and git. Each pass of the kustomize-controller applies the git manifests again, so drift on a field that git declares lasts at most one interval.

## Scale a Flux-managed Deployment

```bash
kubectl scale deployment dialplan -n app-services --replicas=5
kubectl get deploy dialplan -n app-services
```{{exec}}

The Deployment wants 5. Git declares 2.

## Run a pass

The interval is 1m. Ask for a pass now instead of waiting:

```bash
flux reconcile kustomization apps
kubectl get deploy dialplan -n app-services
```{{exec}}

Back to 2. The controller applied the manifest from git with server-side apply and took the `replicas` field back from `kubectl`. A hand fix on a Flux-managed field does not last: the change that lasts is a commit.

```bash
flux events --for Kustomization/apps
```{{exec}}

Near the bottom, a `Progressing` event reads `Deployment/app-services/dialplan configured`. That is the pass that took the field back.

## A HelmRelease keeps the same drift

Scale the Deployment that the `voicemail` HelmRelease installed, and run a pass of that release:

```bash
kubectl scale deployment voicemail -n app-services --replicas=3
flux reconcile helmrelease voicemail
kubectl get deploy voicemail -n app-services
```{{exec}}

It stays at 3. A `HelmRelease` does not correct drift unless `spec.driftDetection.mode` is `enabled`, and the default is disabled. Put it back by hand:

```bash
kubectl scale deployment voicemail -n app-services --replicas=2
```{{exec}}
