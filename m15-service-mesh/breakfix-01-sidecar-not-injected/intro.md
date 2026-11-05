# M15 — Break/fix 01: Sidecar Not Injected

> Pre-req: the M15 baseline tour.

**Alert:** callers of `session-broker` in `media` get 503.

The usual checks pass. `session-broker` is `Running` and `Ready`, its Service has an endpoint, and nginx serves on port 80. Other `media` workloads work.

Your job: find which link of the mesh request path broke, and repair it without weakening the namespace's `STRICT` mTLS.

The cluster takes 3 to 5 minutes to start. Click **Start** when ready.
