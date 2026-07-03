# Step 4 — Owner references: the chain cascading deletion follows

The operator didn't just create `orion-media` — it stamped an **ownerReference** on it pointing back to the `orion` MediaTenant. That link is what lets Kubernetes clean up automatically.

## The child points at its parent

```bash
kubectl get deployment orion-media -n media -o jsonpath='{.metadata.ownerReferences[0]}'; echo
```{{exec}}

`kind: MediaTenant, name: orion, controller: true` — plus the tenant's `uid`. `controller: true` marks the MediaTenant as the managing owner. The child names its parent by identity (name **and** uid), not just by name.

## The full ownership chain

```bash
kubectl get mediatenant orion -n media -o jsonpath='{.metadata.uid}'; echo
kubectl get deployment orion-media -n media -o jsonpath='{.metadata.ownerReferences[0].uid}'; echo
```{{exec}}

The two uids match — the Deployment's owner *is* this MediaTenant. And the Deployment owns its ReplicaSet, which owns the Pods (the M01 chain), so the whole tree hangs off the CR:

`MediaTenant orion → Deployment orion-media → ReplicaSet → Pods`

## Why it matters

Delete the MediaTenant and the **garbage collector** walks that chain and removes everything under it — you don't clean up the child by hand. (Don't delete anything now; break/fix 03 is what happens when the ownerReference is missing.) The ownerReference is the thread cascading deletion pulls; no thread, no cleanup. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
