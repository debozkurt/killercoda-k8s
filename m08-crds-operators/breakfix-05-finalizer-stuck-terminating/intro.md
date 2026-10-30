# M08 — Break/fix 05: Delete Stuck in Terminating (Finalizer)

> Pre-req: break/fix 04. There a child outlived its owner. Here an owner will not go away.

An engineer ran `kubectl delete mediatenant vega` to offboard a tenant, and the command never returned. `vega` still appears in `kubectl get mediatenants`, and `vega-media` still serves. Nobody knows why the delete hangs. The platform team mentions that the operator was scaled down for maintenance.

Find what blocks the deletion, fix it safely, and let the offboarding finish. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
