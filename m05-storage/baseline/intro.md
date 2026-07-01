# M05 — Baseline Tour

A container's own filesystem is ephemeral: restart it and it reverts to the image, delete the Pod and everything it wrote is gone. That's fine for stateless services, but Polyphone runs stateful ones — `cdr-writer` persisting Call Detail Records, `directory` holding its address book, the StatefulSets keeping per-instance state. For those, the data has to outlive the Pod. The **PersistentVolume / PersistentVolumeClaim** model is how Kubernetes delivers durable storage that survives the Pod's disposable lifecycle.

This tour runs on the full Polyphone fleet — no new workloads. You'll inspect the PVC-backed workloads it already runs, all using the cluster's `local-path` StorageClass (a dynamic, `WaitForFirstConsumer`, ReadWriteOnce, `Delete`-policy provisioner).

Four short steps walk the storage chain:

1. **A claim, a volume, a class** — a `Bound` PVC, the PV a StorageClass provisioned for it, and how they relate
2. **Dynamic provisioning & WaitForFirstConsumer** — how a claim gets a volume on demand, and the healthy `Pending` that isn't a bug
3. **Access modes & data that persists** — RWO, where the volume lives, and data surviving a Pod delete
4. **The get pvc triage** — the one command that splits every storage-stuck Pod, and the whole chain in one view

Nothing to fix here. See what healthy durable storage looks like before the break/fix scenarios snap each link. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
