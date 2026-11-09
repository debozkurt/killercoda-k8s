# Step 1 — Diagnose

## Everything is green

```bash
kubectl get deploy edge-relay -n edge
```{{exec}}

`READY` 1/1. The one Pod is healthy, so no event, log, or failed rollout points anywhere.

## Does the cluster match the render?

```bash
cd /root/edge-relay
kubectl diff -k overlays/prod; echo "exit=$?"
```{{exec}}

No output, and exit=0. The live objects match the render exactly. The cluster runs what the overlay produces, so the render itself holds 1 replica.

```bash
kubectl kustomize overlays/prod | grep -n replicas
```{{exec}}

`replicas: 1`, the base value. The prod change never reached the render.

## Find the change that should set 3

```bash
cat overlays/prod/kustomization.yaml
```{{exec}}

The `patches:` entry is an inline JSON 6902 patch with `target: { kind: Deployment, name: relay }`. A target is a selector. Its `name` is an anchored regular expression, so `relay` means exactly `relay`, not "any name that contains relay". No Deployment is named `relay`.

A selector that matches zero resources is not an error. Kustomize applies the patch to nothing and exits 0. The build, the apply, and the rollout all succeeded, on a render without the change.
