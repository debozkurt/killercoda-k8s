# M07 — Break/fix 04: StatefulSet Update Halt

> Pre-req: breakfix-02. You saw that a StatefulSet waits on an un-Ready Pod. This scenario hits the same rule during an update.

The release pipeline pushed a new image to `session-store`, the 3-replica session cache in `app-services`. The pipeline's job ended, and `kubectl get statefulset` reads `READY 2/3`. The cache still answers requests, so no alert fired. The release never finished.

Your job: find which Pods run the new revision and which run the old one, find why the rollout stopped, and bring the set back to 3/3 without restarting the members that serve traffic.

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
