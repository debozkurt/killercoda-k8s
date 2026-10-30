# Step 4 — Owner references: the chain cascading deletion follows

The operator also stamped an **ownerReference** on each child. It points back at the MediaTenant, and the garbage collector reads it.

## The child names its parent

```bash
kubectl get deployment orion-media -n media -o yaml | head -n 30
```{{exec}}

In `metadata`, read `ownerReferences`: `kind: MediaTenant`, `name: orion`, `controller: true`, and a `uid`. The `controller: true` field marks the single managing owner. The reference names the owner by identity, name and uid, so a new object that reuses the name does not match.

## Compare the uid

```bash
kubectl get mediatenant orion -n media -o yaml | head -n 20
```{{exec}}

The `uid` in `metadata` equals the `uid` in the Deployment's `ownerReferences`. The Deployment owns its ReplicaSet, which owns the Pods (the M01 chain), so the whole tree hangs from the custom resource:

```
MediaTenant orion -> Deployment orion-media -> ReplicaSet -> Pods
```

Step 5 deletes a tenant and shows the tree go. No ownerReference means no thread for the garbage collector to follow.
