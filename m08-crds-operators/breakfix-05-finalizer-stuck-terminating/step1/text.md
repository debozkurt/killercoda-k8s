# Step 1 — Diagnose the stuck deletion

`vega` is deleting and not deleted. Read the object, then find who should finish the job.

## The tenant is still there

```bash
kubectl get mediatenants -A
kubectl describe mediatenant vega -n media
```{{exec}}

`vega` is listed. In the `Metadata:` block read two fields. `Deletion Timestamp:` is set, so the API server accepted the delete. `Finalizers:` holds `polyphone.example/media-cleanup`. A **finalizer** is a key in `metadata.finalizers`. While one exists, the API server does not remove the object. It sets `deletionTimestamp` and waits for a controller to finish its cleanup and remove the key.

## Who owns that finalizer?

```bash
kubectl get pods -n platform
kubectl get deployment tenant-operator -n platform
```{{exec}}

The tenant-operator adds this finalizer, and it removes it. The first command lists no Pods. The Deployment reads READY 0/0, because someone scaled it to zero. No controller exists to run the cleanup, so the delete never finishes. `vega-media` keeps running, because cascading deletion starts only after the owner disappears.
