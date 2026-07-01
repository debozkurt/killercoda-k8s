# Step 1 — Diagnose the Bound-but-stuck volume

This time `get pvc` will look *fine*. That's the whole point — the claim is bound, and a Pod is still stuck. Read the shape carefully.

## See the split

```bash
kubectl get pods -n app-services -l app=directory -o wide
```{{exec}}

Two replicas: one `Running`, one `Pending` — and the `NODE` column shows the `Running` one landed on a node while the `Pending` one has none. Now check the claim:

```bash
kubectl get pvc -n app-services
```{{exec}}

`directory-data` is `Bound`. This is the discriminator for the third leaf: the claim isn't `Pending` (break/fix 01) and isn't absent (break/fix 02) — it's healthy, and a Pod is *still* stuck. When a `Bound` claim can't get a Pod running, the problem is at **attach**, not binding.

## Read why the stuck replica won't schedule

```bash
kubectl describe pod -n app-services -l app=directory | grep -A6 Events
```{{exec}}

The scheduling failure names it: `... node(s) had volume node affinity conflict ...`. The `directory-data` volume is `ReadWriteOnce` and lives on one node; the stuck replica was pushed to a *different* node (the two replicas are forced apart — a scheduling rule, M06), and an RWO volume can't be attached on a second node. See where the volume is pinned:

```bash
PV=$(kubectl get pvc directory-data -n app-services -o jsonpath='{.spec.volumeName}')
kubectl describe pv "$PV" | grep -A3 'Node Affinity'
```{{exec}}

The PV's node affinity ties it to the node that holds the `Running` replica. That's `ReadWriteOnce` doing exactly what it promises — one node at a time. (On a cloud block volume the same conflict surfaces as `Multi-Attach error` instead; same rule, different words.) The bug isn't a broken volume; it's asking one RWO volume to serve two nodes. On to the fix.
