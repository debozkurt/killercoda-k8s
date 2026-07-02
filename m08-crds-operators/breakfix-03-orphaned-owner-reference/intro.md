# M08 — Break/fix 03: Orphaned Child (Missing Owner Reference)

> Pre-req: breakfix-01 and 02. Those broke the way *in* (create a resource, reconcile it). This breaks the way *out* — cleanup.

Tenant `vega` was offboarded weeks ago: its `MediaTenant` was deleted. Deleting a MediaTenant is supposed to take its child media Deployment with it automatically — that's cascading deletion. But a capacity review just found `vega-media` still `Running` in the `media` namespace, quietly holding two replicas for a customer that no longer exists.

The operator is healthy — `orion` and `lyra` are `Ready`, their children owned and running. There's no `vega` MediaTenant to reconcile, and the operator only manages children of tenants that exist, so it leaves `vega-media` alone. The question is why the cluster's garbage collector didn't remove `vega-media` when `vega` was deleted.

Your job: find what's different about `vega-media` compared to a properly-managed child like `orion-media`, explain why it was orphaned instead of collected, and reclaim its capacity. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
