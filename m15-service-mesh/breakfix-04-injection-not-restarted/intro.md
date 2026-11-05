# M15 — Break/fix 04: Injection Not Restarted

> Pre-req: the M15 baseline tour.

**Alert:** `session-dialer` in the `signaling` namespace cannot reach `session-broker` in `media`.

Yesterday the platform team enrolled `signaling` in the mesh, so that its callers can reach the `STRICT` services in `media`. No workload in `signaling` changed after that. Callers inside `media` still reach `session-broker`.

Your job: find why `session-dialer` fails, and fix it without weakening `STRICT` in `media`.

The cluster takes 3 to 5 minutes to start. Click **Start** when ready.
