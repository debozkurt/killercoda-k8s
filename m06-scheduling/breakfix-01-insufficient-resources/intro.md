# M06 — Break/fix 01: Insufficient Resources

> Pre-req: the M06 baseline tour. You placed a Pod and watched its request reserve room on the worker. This Pod fits nowhere.

A new analytics workload, `stream-analyzer`, rolled out to the `analytics` namespace. Its Deployment reports zero available replicas. Its Pod never starts and sits `Pending`. No container has run, so there are no logs to read and nothing to restart.

This is the most literal scheduling failure. The Pod asks for more of a resource than any node can give it, so the scheduler places it nowhere. One event on the Pod holds the whole diagnosis.

Your job: read the `FailedScheduling` event, confirm what the Pod is short of, and right-size the request. The image, the application and the nodes are not the problem, so leave them alone.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
