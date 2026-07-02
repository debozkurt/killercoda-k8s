# Step 1 — Diagnose the missing headless Service

The Pods are healthy but mutually invisible. Confirm both halves of that before you touch anything.

## The Pods are up and named correctly

```bash
kubectl get statefulset session-store -n app-services
kubectl get pods -n app-services -l app=session-store
```{{exec}}

`READY 3/3`; `session-store-0`, `-1`, `-2` all `Running`. Ordinal identity and storage are fine — this is *not* a crash or a scheduling problem.

## The per-Pod name doesn't resolve

Try to reach a specific member the way its peers would:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  nslookup session-store-0.session-store.app-services.svc.cluster.local
```{{exec}}

NXDOMAIN — `can't resolve`. The name that's supposed to identify ordinal 0 points at nothing. That name is served by the StatefulSet's **governing Service**, so look at it.

## The governing Service is missing

Which Service does the StatefulSet expect?

```bash
kubectl get statefulset session-store -n app-services -o jsonpath='{.spec.serviceName}'; echo
```{{exec}}

`session-store`. Now list the Services in the namespace:

```bash
kubectl get svc -n app-services
```{{exec}}

There's no `session-store` Service. That's the whole bug: `spec.serviceName` names a Service that was never created. A StatefulSet does **not** create its governing Service — you do — and without a **headless** Service (`clusterIP: None`) selecting these Pods, cluster DNS has nothing from which to publish the per-Pod A records. The Pods run; their names don't resolve. On to the fix.
