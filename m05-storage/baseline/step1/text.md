# Step 1 — A claim, a volume, a class

Durable storage is three objects that reference each other: a **PVC** (the request), a **PV** (the actual volume), and a **StorageClass** (the recipe that provisioned the PV). A Pod names only the claim. Learn to read all three and how they bind, and the rest of the module follows.

## See the claims the fleet holds

```bash
kubectl get pvc -A
```{{exec}}

Every PVC-backed workload has one: `cdr-data` in `cdr-storage`, `directory-data` in `app-services`, and the per-Pod claims the StatefulSets mint (`state-media-engine-0`, `state-presence-0`, …). The `STATUS` column reads `Bound` — the claim found a volume. Look at one closely:

```bash
kubectl describe pvc cdr-data -n cdr-storage
```{{exec}}

Read four lines: `Status: Bound`, `Capacity: 1Gi`, `Access Modes: RWO`, `StorageClass: local-path`, and `Volume:` — the name of the PV it bound to (something like `pvc-9f3c…`). The claim asked for 1Gi RWO; the class provisioned a PV to match; they bound.

## See the volume it bound to

```bash
kubectl get pv
```{{exec}}

Each PV lists its `CAPACITY`, `ACCESS MODES` (RWO), `RECLAIM POLICY` (Delete), `STATUS` (Bound), and — under `CLAIM` — which PVC owns it, e.g. `cdr-storage/cdr-data`. That back-reference is the binding: this PV belongs exclusively to that one claim. PVs are **cluster-scoped** (no namespace), while PVCs are namespaced — the claim is the tenant-facing handle, the volume is the cluster resource.

## See the class that made it

```bash
kubectl get storageclass
```{{exec}}

There's one class, `local-path`. A StorageClass is a named recipe for provisioning volumes — the PVC named it by `storageClassName`, and creating the claim triggered the class to carve a PV automatically. That's **dynamic provisioning**: no admin pre-created the volume. The chain, end to end: the Pod names the PVC, the PVC names the StorageClass, the StorageClass provisioned the PV. Next, watch that provisioning happen — and meet a `Pending` that's perfectly healthy.
