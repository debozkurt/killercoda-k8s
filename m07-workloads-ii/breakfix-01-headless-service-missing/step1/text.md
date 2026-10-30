# Step 1 — Diagnose the missing headless Service

The Pods are healthy and cannot find each other. Confirm both halves before you change anything.

## The Pods are up

```bash
kubectl get statefulset session-store -n app-services
kubectl get pods -n app-services -l app=session-store
```{{exec}}

`READY 3/3`, and `session-store-0`, `-1` and `-2` are all `Running`. The ordinal names and the claims are intact. This is not a crash and not a scheduling problem.

## The per-Pod name does not resolve

Look up one member the way its peers do:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  nslookup session-store-0.session-store.app-services.svc.cluster.local
```{{exec}}

The lookup fails with `NXDOMAIN`. Cluster DNS publishes per-Pod names through the StatefulSet's **governing Service**, so read which Service the StatefulSet expects:

```bash
kubectl get statefulset session-store -n app-services -o yaml | grep serviceName
```{{exec}}

The line reads `serviceName: session-store`. List the Services in the namespace:

```bash
kubectl get svc -n app-services
```{{exec}}

No Service named `session-store` exists. A StatefulSet does not create its governing Service. You create it, and it must be headless (`clusterIP: None`). Without a headless Service that selects these Pods, cluster DNS has nothing to publish. Next: create it.
