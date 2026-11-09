# M16 — Break/fix 02: Generator Name Mismatch

> Pre-req: the M16 baseline tour.

**Alert:** `edge-relay` in prod is at 0 of 3 available replicas.

The deploy job ran `kubectl apply -k overlays/prod` from `/root/edge-relay` and reported success. Every object was created. The relay has not served a call since.

Your job: find why the Pods do not start, and fix it in the Kustomize tree.

The cluster takes 60 to 120 seconds to start. Click **Start** when ready.
