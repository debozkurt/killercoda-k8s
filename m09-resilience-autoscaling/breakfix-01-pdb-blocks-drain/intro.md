# M09 — Break/fix 01: PDB Blocks Drain

A kernel CVE landed and the worker node needs a patch. The plan is routine: `kubectl drain` the worker so its Pods reschedule, patch it, uncordon it. But the drain won't proceed — it stalls, and the eviction it's trying to perform comes back refused.

The workload in the way is `sip-registrar` in `signaling`. It's perfectly healthy — `kubectl get deploy` shows `2/2` Running. Nothing is crashing, nothing is `Pending`. The block isn't the workload; it's the **PodDisruptionBudget** guarding it. Someone set the budget so tight that Kubernetes won't allow *any* replica to be voluntarily removed — which is exactly what a drain needs to do.

Your job: read why the eviction is refused, see the "allowed disruptions" number that governs it, and give the budget enough headroom that maintenance can proceed without dropping the service below its safe floor.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
