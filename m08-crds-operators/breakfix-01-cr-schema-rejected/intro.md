# M08 — Break/fix 01: Custom Resource Rejected by Schema

> Pre-req: the baseline. This scenario breaks the first link: a custom resource that is never created.

A product team asked for a new tenant, `vega`, and gave you a manifest. The operator is healthy. `orion` and `lyra` are `Ready` and their Deployments run. But `vega` is missing: `kubectl get mediatenants -A` lists two tenants, and no `vega-media` Deployment exists.

Nothing crashed, and the operator logged no error, because the operator never saw `vega`. The manifest is at `/root/vega-tenant.yaml`. Apply it, read why the API server refuses it, and get `vega` provisioned.

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
