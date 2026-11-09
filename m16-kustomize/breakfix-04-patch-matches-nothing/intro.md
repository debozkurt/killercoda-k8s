# M16 — Break/fix 04: Patch Matches Nothing

> Pre-req: the M16 baseline tour.

**Alert:** `edge-relay` capacity in prod is one third of plan.

Yesterday the team cleaned up the prod overlay in `/root/edge-relay`. The deploy job ran `kubectl apply -k overlays/prod` and passed, and the rollout completed. Every Pod is `Running` and `Ready`. Prod is planned at 3 replicas.

Your job: find why prod runs fewer replicas than planned, and fix it in the Kustomize tree.

The cluster takes 60 to 120 seconds to start. Click **Start** when ready.
