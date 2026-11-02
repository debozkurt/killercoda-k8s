# M11 — Break/fix 02: Store Access Denied

> The healthy pipeline from the baseline, with one link broken. Work breakfix-01 first.

An alert fires: `billing-processor` in `provisioning` and `partner-connector` in `media` both have no ready Pod. Two workloads in two namespaces fail at the same time.

Two simultaneous failures in unrelated namespaces usually share one dependency. Both consumers read Secrets that one operator writes from one store.

Your job: find the shared cause, prove it with one command, and restore the pipeline without restarting the operator.

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
