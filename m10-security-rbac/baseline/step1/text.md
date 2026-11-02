# Step 1 — Who the Pods are: ServiceAccounts

A **ServiceAccount** is a namespaced identity for the processes in a Pod. Every API request a Pod sends carries that identity.

## Every namespace has a default

```bash
kubectl get serviceaccounts -n media
```{{exec}}

Kubernetes creates a ServiceAccount named `default` in every namespace. A Pod that does not name one runs as `default`.

## Which identity does a fleet Pod use?

```bash
kubectl describe pod -n media -l app=session-broker | grep -m1 'Service Account'
```{{exec}}

The line reads `Service Account:  default`. No fleet workload sets `serviceAccountName`, so every fleet Pod runs as its namespace's `default`.

## The token is mounted into the container

```bash
kubectl exec -n media deploy/session-broker -- ls /var/run/secrets/kubernetes.io/serviceaccount
```{{exec}}

You see `ca.crt`, `namespace`, and `token`. The kubelet mounts a short-lived token here and rotates it. A client in the container sends this token, and the API server authenticates the caller as `system:serviceaccount:media:default`.

## What may that identity do?

```bash
kubectl auth can-i --list -n media --as=system:serviceaccount:media:default
```{{exec}}

`kubectl auth can-i` asks the API server's authorizer the question directly, and `--as` tests another identity. The list holds only the self-review resources (`selfsubjectreviews` and similar) and discovery paths such as /api and /healthz. Authentication works. Authorization grants almost nothing. A permission is a separate object, and step 2 reads those objects.
