# Step 1 — Diagnose the failed election

The Pods are a red herring. Establish that leadership never happened, then find why.

## The Pods are up, but no Lease is held

```bash
kubectl get pods -n call-routing -l app=call-coordinator
```{{exec}}

Both replicas `Running`, `1/1`. Now look for the leadership lock:

```bash
kubectl get lease call-coordinator -n call-routing
```{{exec}}

`Error from server (NotFound)` — the Lease doesn't exist. In a live controller, the election client *creates* the Lease when it first wins; an absent Lease means no replica ever acquired leadership. The workload is up but leaderless, which is why the singleton work never runs.

## Why can't the client acquire the lock?

Acquiring a Lease means creating (and then updating) that object, which the replica does as its ServiceAccount. Check what that identity is allowed to do — impersonate it with `--as`:

```bash
kubectl auth can-i get    leases.coordination.k8s.io -n call-routing --as=system:serviceaccount:call-routing:coordinator
kubectl auth can-i create leases.coordination.k8s.io -n call-routing --as=system:serviceaccount:call-routing:coordinator
kubectl auth can-i update leases.coordination.k8s.io -n call-routing --as=system:serviceaccount:call-routing:coordinator
```{{exec}}

All three return `no`. The election client can't `get`, `create`, or `update` the Lease — so it can never take the lock. (A real client logs this as `leases.coordination.k8s.io ... is forbidden` and retries forever, never leading.)

## Find the permission gap in the Role

The SA's permissions come from a Role via a RoleBinding. Read them:

```bash
kubectl describe rolebinding leader-election -n call-routing
kubectl get role leader-election -n call-routing -o yaml | grep -A4 'coordination.k8s.io'
```{{exec}}

The RoleBinding ties the `coordinator` ServiceAccount to the `leader-election` Role — but that Role grants only `list` and `watch` on `leases`. The verbs a leader-election client actually needs — `get`, `create`, `update` — are missing. That's the root cause: the identity can *see* Leases but not *hold* one. On to the fix.
