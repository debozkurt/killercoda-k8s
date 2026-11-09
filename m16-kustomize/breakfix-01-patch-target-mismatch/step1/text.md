# Step 1 — Diagnose

## Look at the cluster

```bash
kubectl get deploy -n edge
```{{exec}}

`No resources found in edge namespace.` The fleet's edge workloads are a DaemonSet and a StatefulSet, and `edge-relay` should be the one Deployment here. It is not crashing and not pending. It is absent. Nothing exists to `describe`. When `apply -k` leaves no object behind, suspect the build.

## Run the build yourself

`apply -k` builds the overlay first. Run only that half:

```bash
cd /root/edge-relay
kubectl kustomize overlays/prod; echo "exit=$?"
```{{exec}}

No manifests: one error line and exit=1. The line ends with:

```text
no matches for Id Deployment.v1.apps/edge-relayer.[noNs]; failed to find unique target for patch Deployment.v1.apps/edge-relayer.[noNs]
```

(Newer `kubectl` versions put `no resource matches strategic merge patch` in front of the same text.) Kustomize holds a patch for `Deployment/edge-relayer`, and the build contains no resource with that identity.

## Line up the two names

```bash
cat overlays/prod/replicas-patch.yaml
```{{exec}}

The patch file is a partial Deployment named `edge-relayer`. It has no `target:` in the overlay, so its own kind and `metadata.name` select the resource it changes.

```bash
cat base/deployment.yaml
```{{exec}}

The base Deployment's `name:` reads `edge-relay`. The patch names a resource the build never holds, so Kustomize stops the build, and `apply -k` sends nothing to the API server.
