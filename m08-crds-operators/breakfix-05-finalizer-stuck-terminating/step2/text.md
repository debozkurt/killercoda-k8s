# Step 2 — Fix it and verify

Bring the controller back. It runs its cleanup and removes its own finalizer. Do not edit the finalizer by hand.

## Restore the operator

```bash
kubectl scale deployment tenant-operator -n platform --replicas=1
kubectl rollout status deployment/tenant-operator -n platform --timeout=90s
```{{exec}}

The new Pod lists the tenants and finds `vega` with a deletion timestamp. It runs the cleanup and removes the finalizer. Read the proof:

```bash
sleep 10
kubectl logs deployment/tenant-operator -n platform --tail=8
kubectl get mediatenants -A
```{{exec}}

The log shows `media/vega: cleanup done, finalizer removed`. The API server then deletes `vega`, and the list shows two tenants.

## The cascade follows

```bash
sleep 10
kubectl get deployments -n media -l managed-by=tenant-operator
```{{exec}}

`vega-media` is gone. Its ownerReference named `vega`, and the collector acted once `vega` disappeared.

You could have removed the finalizer with `kubectl patch`. That deletes the object at once and skips the cleanup, so whatever the finalizer guarded leaks. Use that move only when you know the cleanup is done or no longer matters.
