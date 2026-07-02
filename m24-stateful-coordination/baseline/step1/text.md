# Step 1 — Stable identity & persistent per-Pod storage

A Deployment's Pods are cattle: random-suffixed names, interchangeable, no memory of which was which. A **StatefulSet** makes them pets — each replica gets a fixed **ordinal identity** (`-0`, `-1`, `-2`) that it keeps across restarts, and its own volume that follows that identity.

## See the ordinal identity

```bash
kubectl get statefulset -n media session-cache
kubectl get pods -n media -l app=session-cache -o wide
```{{exec}}

The pods are `session-cache-0`, `session-cache-1`, `session-cache-2` — stable, numbered from zero, not random hashes. Contrast a Deployment:

```bash
kubectl get pods -n call-routing -l app=call-coordinator
```{{exec}}

`call-coordinator-<replicaset-hash>-<random>` — no stable identity; any Pod is as good as any other. The StatefulSet's ordinals are the difference: `session-cache-0` is always the same logical member, and if its Pod dies the replacement is *also* named `session-cache-0`, on the same identity.

## See the per-Pod persistent cache

Each replica gets its own PVC, minted from the StatefulSet's `volumeClaimTemplates`:

```bash
kubectl get pvc -n media -l app=session-cache
```{{exec}}

There are three — `data-session-cache-0`, `data-session-cache-1`, `data-session-cache-2` — one per ordinal, each `Bound` to its own PV. This is the workload's **persistent cache**: `session-cache-0`'s data lives in `data-session-cache-0`, and that binding is sticky. Delete the Pod and the replacement `session-cache-0` re-mounts the *same* PVC — its cache survives. (The storage mechanics themselves are M05; here the point is that the volume is pinned to the *identity*, not the Pod.)

```bash
kubectl get statefulset session-cache -n media \
  -o jsonpath='{.spec.volumeClaimTemplates[0].metadata.name}{"\n"}'
```{{exec}}

The template is named `data`; the StatefulSet expands it to `data-<pod-name>` per replica. Stable name + sticky storage is what lets a member rejoin the cluster as *itself* after a restart. Next: how peers find a specific member by name.
