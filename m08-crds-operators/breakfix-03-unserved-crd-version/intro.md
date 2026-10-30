# M08 — Break/fix 03: Reconciliation Stuck (Unserved CRD Version)

> Pre-req: break/fix 02. The symptom is the same: valid tenants, a `Running` operator, no progress. The cause differs, and the first check you ran last time does not find it.

A platform release updated the `MediaTenant` CRD. The tenants `orion` and `lyra` exist, but their `PHASE` and `READY` columns are blank and no child Deployment exists. The operator Pod is `Running`.

Work out why this operator makes no progress, and restore it. Rule out the cause from the previous scenario first. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
