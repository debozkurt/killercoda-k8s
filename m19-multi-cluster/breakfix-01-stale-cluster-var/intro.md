# M19 — Break/fix 01: Stale Cluster Variable

> Pre-req: the M19 baseline tour. You've seen a fleet composed from base → region → cluster, and traced values to their layers. This one has a value that's wrong for exactly one region.

An on-call page says `edge-relay` in `eu-central-1` is emitting `us-east-1` in its telemetry — calls are being tagged to the wrong region. Nobody deployed anything unusual; the cluster is `Running` and healthy. That's the tell for a whole class of fleet bugs: the render is valid, the apply succeeded, the workload runs — and the *value* is simply wrong for that cluster.

`eu-central-1` is a newer region. Its overlay was created the way region overlays always are — by cloning the nearest sibling (`us-east-1`) and changing what differs. Something didn't get changed. Your job: render the affected cluster, find the wrong value, and trace it up the layer path to the one file that owns it.

The fleet repo is at `/root/fleet`. The `prod-eu-central-1` cluster is already applied into the `edge` namespace. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
