# Step 1 — Diagnose

## Which spec is live

```bash
kubectl get deploy edge-relay -n edge -o wide
```{{exec}}

`READY` 1/1 and `IMAGES` nginx:1.25: the lab spec. Prod wants 3 replicas on nginx:1.27.

## Ask the API server first

`kubectl diff -k` sends the render as a dry run, so it fails the same way the apply did, and changes nothing:

```bash
cd /root/edge-relay
kubectl diff -k overlays/prod
```{{exec}}

The error reads `The Deployment "edge-relay" is invalid: spec.selector: Invalid value: ... field is immutable`. The build worked; the API server refuses the object. A Deployment's selector is immutable after creation, because it is how the Deployment finds the ReplicaSets and Pods it owns.

## Compare the selectors

```bash
kubectl describe deploy edge-relay -n edge
```{{exec}}

The `Selector:` line reads `app=edge-relay`. Now the selector in the render:

```bash
kubectl kustomize overlays/prod | grep -n -A3 'selector:'
```{{exec}}

Both the Service and the Deployment selectors gain `tier: prod`. A Service selector may change. A Deployment selector may not.

## Why calls fail

`apply -k` is not a transaction. It sends each object on its own, and only the Deployment was rejected:

```bash
kubectl describe svc edge-relay -n edge
```{{exec}}

`Selector:` reads `app=edge-relay,tier=prod`, and `Endpoints:` reads `<none>`. The Service update succeeded. The running Pods carry no `tier` label, so the Service selects none of them.

## Find the transformer

```bash
cat overlays/prod/kustomization.yaml
```{{exec}}

The overlay sets `tier: prod` with `commonLabels`. `commonLabels` writes its labels into metadata, Pod templates, and every selector. On a first create that is harmless. Over a running Deployment it changes an immutable field. (Newer `kubectl` versions also print a deprecation warning for `commonLabels`.)
