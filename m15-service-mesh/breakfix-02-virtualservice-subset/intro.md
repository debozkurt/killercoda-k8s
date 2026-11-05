# M15 — Break/fix 02: VirtualService Subset

> Pre-req: the M15 baseline tour.

**Alert:** every call to `session-broker` returns 503.

Every `media` pod is 2/2 and `Ready`. `istioctl proxy-status` lists every sidecar as `SYNCED`. The Service has an endpoint. Nothing restarted.

Your job: find the link of the mesh request path that fails, and make the calls succeed again.

The cluster takes 3 to 5 minutes to start. Click **Start** when ready.
