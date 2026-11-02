# M11 — Break/fix 04: Target Write Denied

> The healthy pipeline from the baseline, with one link broken. Work breakfix-01 and 02 first.

An alert fires: `billing-processor` in the `provisioning` namespace has no ready Pod. The `media` side of the pipeline is healthy, and its consumer runs.

The operator reads one store and writes Secrets into two namespaces. The store and the operator serve both namespaces, yet only one fails. That asymmetry is your first clue.

Your job: name the broken link, prove it with one command, and fix it with the smallest grant.

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
