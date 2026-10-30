# M08 — Break/fix 02: Reconciliation Stuck (Operator RBAC)

> Pre-req: break/fix 01. There the resource never existed. Here the resources are valid, and the operator cannot act on them.

`orion` and `lyra` applied cleanly and appear in `kubectl get mediatenants`. Neither reaches `Ready`. `PHASE` stays Provisioning, `READY` stays 0, and the `media` namespace has no child Deployments. The capacity was requested and never appeared.

The reflex is to check the operator Pod. It is `Running`, with no restarts. That is the trap. An operator can be a healthy process and a stalled controller. The Pod's status says the program is alive. It says nothing about progress. Read the custom resources' `.status` and the operator's logs instead.

Find in the logs why each reconcile fails, and restore the operator's ability to provision. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
