# M08 — Break/fix 04: Orphaned Child (Missing Owner Reference)

> Pre-req: break/fix 01 to 03 broke the way in: create a resource, reconcile it. This scenario breaks the way out: cleanup.

Tenant `vega` was offboarded weeks ago, and its `MediaTenant` was deleted. Deleting a MediaTenant should delete its child Deployment through cascading deletion. A capacity review found `vega-media` still `Running` in `media`, with two replicas for a customer that no longer exists.

The operator is healthy. `orion` and `lyra` are `Ready` and their children are owned and running. The operator manages only children of tenants that exist, so it ignores `vega-media`. The question is why the garbage collector did not remove it.

Find what differs between `vega-media` and a managed child such as `orion-media`, explain why the collector skipped it, and reclaim the capacity. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
