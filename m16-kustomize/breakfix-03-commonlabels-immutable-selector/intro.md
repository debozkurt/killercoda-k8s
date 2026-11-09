# M16 — Break/fix 03: commonLabels and the Immutable Selector

> Pre-req: the M16 baseline tour.

**Alert:** the `edge-relay` promotion from lab to prod failed.

`edge-relay` runs the lab spec in `edge` and is healthy. The deploy job ran `kubectl apply -k overlays/prod` from `/root/edge-relay` and exited non-zero. The workload still runs one replica of the lab image, and calls to `edge-relay` started to fail at the same time.

Your job: find why the API server refuses the promotion. Then restore traffic and land the prod spec without deleting the Deployment.

The cluster takes 60 to 120 seconds to start. Click **Start** when ready.
