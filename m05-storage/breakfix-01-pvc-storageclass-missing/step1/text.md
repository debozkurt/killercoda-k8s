# Step 1 — Diagnose the unbound PVC

The Pod is `Pending` with no logs, because its container never ran — it's waiting on storage. Don't look for a crash; follow the claim.

## Confirm the symptom

```bash
kubectl get pods -n cdr-storage
```{{exec}}

`cdr-writer` is `Pending`. The Pod's own events name the category but not the cause:

```bash
kubectl describe pod -n cdr-storage -l app=cdr-writer | grep -A5 Events
```{{exec}}

You'll see a scheduling failure about an **unbound PersistentVolumeClaim** — the Pod can't be placed because the volume it needs isn't ready. That points you one object over.

## The first look: get pvc

```bash
kubectl get pvc -n cdr-storage
```{{exec}}

`cdr-data` is `Pending`, not `Bound`. A Pod IS trying to use this claim (that's why the Pod is stuck), so this is not the healthy `WaitForFirstConsumer` case — this claim genuinely can't bind. Ask it why:

```bash
kubectl describe pvc cdr-data -n cdr-storage | grep -A3 Events
```{{exec}}

The event is explicit: `storageclass.storage.k8s.io "fast-ssd" not found`. The claim asked for a StorageClass named `fast-ssd`, and there's no such class, so there's no provisioner to call and no PV is ever created.

## Confirm the class doesn't exist

```bash
kubectl get storageclass
```{{exec}}

The only class on this cluster is `local-path`. There is no `fast-ssd` — a typo or a class that was never installed. The claim is pinned to a provisioner that doesn't exist. On to the fix — with one catch.
