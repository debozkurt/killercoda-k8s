# Step 1 — Who the Pods are: ServiceAccounts & identity

Before "what may this Pod do?" comes "who *is* this Pod?" — its **ServiceAccount**.

## Every namespace has a default SA

```bash
kubectl get serviceaccounts -A | grep -v kube-system | head
```{{exec}}

Kubernetes auto-creates a `default` ServiceAccount in every namespace. Unless you say otherwise, that's who your Pods are.

## Which SA does a fleet Pod run as?

```bash
kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].spec.serviceAccountName}'; echo
```{{exec}}

`default` — nobody set `serviceAccountName`, so the Pod adopted the namespace default. Every fleet workload runs this way.

## The token is projected into the container

```bash
kubectl exec -n media deploy/session-broker -- ls /var/run/secrets/kubernetes.io/serviceaccount
```{{exec}}

`ca.crt  namespace  token`. That `token` is the **bound service account token** — a short-lived JWT the kubelet projects in and rotates; it's how the Pod authenticates to the API server as `system:serviceaccount:media:default`.

## What can that identity actually do?

```bash
kubectl auth can-i --list --as=system:serviceaccount:media:default -n media | head
```{{exec}}

The `default` SA authenticates fine but is authorized for almost nothing — just self-review endpoints (`selfsubjectreviews`, `selfsubjectaccessreviews`). Identity is step one; a *permission* is a separate thing you grant with RBAC. That's next.
