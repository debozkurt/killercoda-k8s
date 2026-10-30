# Step 1 — Rolling updates and rollback

A **Deployment** is a controller that keeps a set of identical Pods running. When you change the Pod template, it replaces the Pods a few at a time, so the service keeps serving.

## Read the update strategy

```bash
kubectl describe deployment route-engine -n call-routing
```{{exec}}

Find the `StrategyType:` and `RollingUpdateStrategy:` lines. They read RollingUpdate and 25% max unavailable, 25% max surge. With 2 replicas, surge rounds up to 1 extra Pod and unavailable rounds down to 0. The Deployment never takes a Pod down before its replacement is Ready.

## Revision history

Each template change is a numbered **revision**. Kubernetes keeps recent ones so you can rewind:

```bash
kubectl rollout history deployment/route-engine -n call-routing
```{{exec}}

## Run a healthy rollout

`rollout restart` re-rolls the Deployment with the same template. `rollout status` blocks until the new Pods are Ready, then prints successfully rolled out. Deploy pipelines use that command to know a release landed.

```bash
kubectl rollout restart deployment/route-engine -n call-routing
kubectl rollout status deployment/route-engine -n call-routing
kubectl get rs -n call-routing -l app=route-engine
```{{exec}}

One **ReplicaSet** (the object that owns the Pods) holds the desired count. Older ReplicaSets sit at 0, kept for rollback. A rollout scales one ReplicaSet up while it scales another down.

## Rewind

```bash
kubectl rollout undo deployment/route-engine -n call-routing
kubectl rollout status deployment/route-engine -n call-routing
```{{exec}}

`rollout undo` re-applies the previous revision's template and rolls forward to it. Next: scale the replica count automatically.
