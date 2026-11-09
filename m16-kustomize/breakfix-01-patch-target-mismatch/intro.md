# M16 — Break/fix 01: Patch Target Mismatch

> Pre-req: the M16 baseline tour.

**Alert:** the deploy job for the `edge-relay` prod promotion failed.

The job runs `kubectl apply -k overlays/prod` from `/root/edge-relay` and exits non-zero. The rest of the fleet is healthy. Nobody has looked at the cluster yet.

Your job: find why the promotion fails, and land prod at 3 replicas.

The cluster takes 60 to 120 seconds to start. Click **Start** when ready.
