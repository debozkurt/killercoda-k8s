# Step 4 — Leader election with Leases

Stable identity solves "which member is which." Leadership solves "which member does the singleton work" — the job exactly one replica may do at a time (write the authoritative routing table, drive a migration). Kubernetes' primitive for that is a **Lease**: a small `coordination.k8s.io` object that acts as a lock. One replica holds it and renews it to stay leader; if it stops renewing, another takes over.

## Kubernetes elects its own leaders this way

The control plane runs its own singletons — the scheduler and controller-manager run as multiple replicas but only one is active — and they use Leases you can read:

```bash
kubectl get lease -n kube-system kube-scheduler kube-controller-manager
```{{exec}}

`HOLDER` names the instance currently leading. That's the same mechanism your workloads use.

## Read the call-coordinator Lease

`call-coordinator` is a 2-replica active/standby singleton. Its Lease records the leader:

```bash
kubectl get lease -n call-routing
kubectl get lease call-coordinator -n call-routing -o yaml
```{{exec}}

Read four fields under `spec`:

- `holderIdentity` — the replica that currently holds the lock (the leader). The standby sees this and stays passive.
- `leaseDurationSeconds` — how long the lock is valid without a renewal (here 15s). If the holder goes silent for longer, the lock is considered expired and a challenger may claim it.
- `renewTime` — when the holder last proved it's alive. A live leader bumps this every few seconds; a `renewTime` that stops advancing is a leader that died.
- `acquireTime` — when the current holder first took the lock.

The whole protocol is those fields: hold, renew before expiry, and if you can't, let someone else take over.

## The permission that makes the lock work

To hold a Lease, the leader's ServiceAccount must be allowed to read and write it. Check what `call-coordinator`'s identity can do:

```bash
kubectl auth can-i get    leases.coordination.k8s.io -n call-routing --as=system:serviceaccount:call-routing:coordinator
kubectl auth can-i create leases.coordination.k8s.io -n call-routing --as=system:serviceaccount:call-routing:coordinator
kubectl auth can-i update leases.coordination.k8s.io -n call-routing --as=system:serviceaccount:call-routing:coordinator
```{{exec}}

All three return `yes` — `get`, `create`, and `update` on `leases` are exactly what a leader-election client needs to acquire the lock and renew it. Take any of them away and no replica can ever become leader, which is precisely the failure break/fix 03 stages. That's the coordination stack end to end — identity, discovery, ordering, leadership. See `finish.md` for what's next.
