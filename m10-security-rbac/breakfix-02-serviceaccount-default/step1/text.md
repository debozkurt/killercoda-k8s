# Step 1 — Diagnose the Forbidden

The symptom matches break/fix 01. Read the identity field first.

## Confirm the crash loop and read the logs

```bash
kubectl get pods -n call-routing -l app=route-watcher
kubectl logs -n call-routing deploy/route-watcher --tail=8
```{{exec}}

```text
endpoints is forbidden: User "system:serviceaccount:call-routing:default"
cannot list resource "endpoints" in API group "" in the namespace "call-routing"
```

The verb, resource, API group, and scope match break/fix 01. The identity is `default`, the namespace's default ServiceAccount, and not a dedicated account.

## Test both identities

```bash
kubectl get serviceaccounts -n call-routing
kubectl auth can-i list endpoints -n call-routing --as=system:serviceaccount:call-routing:route-watcher
kubectl auth can-i list endpoints -n call-routing --as=system:serviceaccount:call-routing:default
```{{exec}}

A `route-watcher` ServiceAccount exists. It gets yes, and `default` gets no. The grant is correct, and the Pod does not use it.

## Read the Pod's identity

```bash
kubectl describe pod -n call-routing -l app=route-watcher | grep -m1 'Service Account'
```{{exec}}

`Service Account:  default`. The Deployment's Pod template sets no `serviceAccountName`, so each Pod falls back to `default`.
