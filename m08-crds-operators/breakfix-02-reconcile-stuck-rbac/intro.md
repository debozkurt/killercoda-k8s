# M08 — Break/fix 02: Reconciliation Stuck (Operator RBAC)

> Pre-req: breakfix-01. There, the resource never existed. Here the resources are valid — the operator can't act on them.

Both MediaTenants, `orion` and `lyra`, applied cleanly and show up in `kubectl get mediatenants`. But neither ever reaches `Ready`: their `PHASE` sits at `Provisioning`, `READY` at 0, and there are **no** child media Deployments in the `media` namespace. Capacity was requested and never appeared.

The reflex is to look at the operator Pod — and it's `Running`, not crashing, not restarting. That's the trap. An operator can be perfectly healthy as a *process* and still make zero progress as a *controller*. The signal isn't the Pod's status; it's in the custom resources' `.status` (stuck) and the operator's own logs (what it tried and what stopped it).

Your job: read the stuck state, find in the operator's logs why each reconcile fails, and restore its ability to provision. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
