# Step 3 — Access modes & data that persists

The point of a PVC is that data outlives the Pod. Prove it — and see the access mode that governs *where* the volume can be mounted.

## Read the access mode and where the volume lives

```bash
kubectl get pv
```{{exec}}

The `ACCESS MODES` column reads `RWO` — **ReadWriteOnce**: the volume can be mounted read-write by a single *node* at a time. ("Once" means one node, not one Pod — a detail break/fix 03 turns on.) For this `local-path` volume, that node is fixed, because the storage is a directory on one machine's disk:

```bash
PV=$(kubectl get pvc cdr-data -n cdr-storage -o jsonpath='{.spec.volumeName}')
kubectl describe pv "$PV" | grep -A3 'Node Affinity'
```{{exec}}

`Node Affinity` pins the PV to the node that holds the directory. The volume isn't floating in the cluster; it lives on one node, and any Pod that mounts it must run there.

## Write data, then destroy the Pod

`cdr-writer` mounts `cdr-data` at `/data`. Write a record into it:

```bash
POD=$(kubectl get pods -n cdr-storage -l app=cdr-writer -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n cdr-storage "$POD" -- sh -c 'echo "cdr-2026-07-01-000042" > /data/record && cat /data/record'
```{{exec}}

Now delete the Pod — the Deployment will make a new one:

```bash
kubectl delete pod -n cdr-storage "$POD"
kubectl wait --for=condition=Ready pod -l app=cdr-writer -n cdr-storage --timeout=60s
```{{exec}}

## Confirm the data survived

```bash
NEWPOD=$(kubectl get pods -n cdr-storage -l app=cdr-writer -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n cdr-storage "$NEWPOD" -- cat /data/record
```{{exec}}

The record is still there — a different Pod, the same volume. The container's own filesystem was thrown away with the old Pod; the PVC's data wasn't, because it lives in the PV, not the Pod. That persistence across the Pod's lifecycle is the entire reason PersistentVolumes exist. Next: the one command that diagnoses when this chain breaks.
