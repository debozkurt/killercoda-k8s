# M08 — Break/fix 01: Custom Resource Rejected by Schema

> Pre-req: the baseline tour (CRD, custom resources, the operator). This scenario breaks the first link — a custom resource that never gets created.

A product team asked for a new tenant, `vega`, and handed you a manifest to apply. The operator that provisions tenants is healthy — `orion` and `lyra` are `Ready`, their child Deployments running — but `vega` is nowhere: `kubectl get mediatenants -A` lists only the two originals, and there's no `vega-media` Deployment.

There's no crash to chase and no operator error, because the operator never saw `vega` — the custom resource was never created. The manifest the team gave you is at `/root/vega-tenant.yaml`. Your job: apply it, read exactly why the API server refuses it, and get `vega` provisioned.

The CRD registers a schema for MediaTenants, and the API server validates every custom resource against it. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
