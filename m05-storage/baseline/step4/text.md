# Step 4 — The get pvc triage

When a Pod is stuck on storage, it sits in `Pending` or `ContainerCreating` and never logs anything — the problem is in a claim or a volume the Pod never names in its own events. One command is the first look, and it splits the failure three ways.

## The first-look command

```bash
kubectl get pvc -A
```{{exec}}

For every PVC-backed workload, the `STATUS` column is the diagnosis. Three outcomes, three different problems:

- **`Bound`** — the claim has its volume. Storage is fine; if the Pod is stuck, look elsewhere (or at attach — see below).
- **`Pending`** — the claim can't get a volume. Bad or missing StorageClass, or no matching PV. (Unless no Pod is using it yet — then it's healthy `WaitForFirstConsumer`.)
- **the claim you expected isn't listed** — the Pod names a `claimName` that doesn't exist in this namespace. A typo, or the claim is in another namespace.

That's the whole differential. `kubectl get pvc` is to storage what `kubectl get endpoints` was to Services in M04: the Pod's status says it's stuck; the claim says why.

## See the chain from the Pod's side

```bash
POD=$(kubectl get pods -n cdr-storage -l app=cdr-writer -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "$POD" -n cdr-storage | grep -A4 'Volumes:'
```{{exec}}

The `Volumes:` section shows the Pod mounting a volume whose type is `PersistentVolumeClaim` with `ClaimName: cdr-data`. That `ClaimName` is the only storage reference the Pod holds — everything else (the PV, the class, the disk) hangs off the claim. Follow it:

```bash
kubectl get pvc cdr-data -n cdr-storage        # Bound → a PV
kubectl get pv                                  # the PV, CLAIM = cdr-storage/cdr-data
```{{exec}}

Pod → `claimName` → PVC → StorageClass → PV → a directory on a node. That's the healthy chain, and every break/fix in this module snaps exactly one link. Internalize `get pvc` as the reflex — see `finish.md` for what's next.
