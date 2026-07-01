# M06 — Break/fix 01: Insufficient Resources

> Pre-req: the M06 baseline tour. You've read healthy placement and the Allocatable headroom; this is a Pod that fits nowhere.

A new analytics workload, `stream-analyzer`, was rolled out to the `analytics` namespace. Its Deployment reports zero available replicas and the Pod never starts — it sits `Pending`. No container has run, so there are no logs to read and nothing to restart.

This is the first and most literal scheduling failure: the Pod is asking for more of a resource than any node can give it, so the scheduler can't place it anywhere. The whole diagnosis is in one event on the Pod. Your job: read the `FailedScheduling` message, confirm what it's short on, and right-size the request — without touching the image, the app, or the nodes, none of which are the problem.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
