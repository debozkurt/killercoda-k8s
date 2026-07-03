# Step 1 — Kyverno as admission webhooks

A policy engine is a controller that reads policy objects and enforces them by acting as **admission webhooks** — the API server calls it during admission, after RBAC. See it running, read its policies, and confirm it wired itself into the request path.

## The engine's Pods

```bash
kubectl get pods -n kyverno
```{{exec}}

Four controllers, all `Running`: `kyverno-admission-controller` (the webhook callback the API server hits), plus background, reports, and cleanup controllers. The admission controller is the one in the write path.

## The policies it enforces

```bash
kubectl get clusterpolicy
```{{exec}}

Three, all `READY`: `require-resource-limits`, `add-owner-label`, `disallow-latest-tag`. A `ClusterPolicy` is a cluster-scoped Kubernetes object — policy expressed as YAML, no separate language. `READY: true` means Kyverno has registered the webhooks for it.

## The webhooks it registered

```bash
kubectl get validatingwebhookconfiguration | grep kyverno
kubectl get mutatingwebhookconfiguration | grep kyverno
```{{exec}}

Kyverno dynamically registers a validating webhook (for the `validate` rules) and a mutating one (for `mutate`). It only intercepts the kinds and namespaces its policies actually match — here, Pods in `tenant-apps` — so it isn't in the path of anything else. That scoping is what keeps a policy engine from being a cluster-wide single point of failure.
