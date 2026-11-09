# M16 — Break/fix 05: Hash Disabled, Stale Config

> Pre-req: the M16 baseline tour.

**Alert:** `edge-relay` in prod still rejects sessions above 5000.

Yesterday the team raised `MAX_SESSIONS` from 5000 to 6000 in the prod overlay at `/root/edge-relay`, and the deploy job applied it with `kubectl apply -k overlays/prod`. The job passed. Every Pod is `Running` and `Ready`. Last month the same team changed the overlay to stop old ConfigMaps from accumulating.

Your job: find why the relay still enforces 5000, and fix it so that the next config change does not repeat this.

The cluster takes 60 to 120 seconds to start. Click **Start** when ready.
