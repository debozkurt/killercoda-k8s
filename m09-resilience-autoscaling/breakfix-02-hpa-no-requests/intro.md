# M09 — Break/fix 02: HPA Can't Read Its Metric

> Pre-req: the baseline tour. You saw a healthy HPA reading CPU utilization as a percentage of the container's request. This one can't.

`transcode-scaler` in `media` was set up to autoscale on CPU — 1 to 5 replicas, targeting 50% utilization — so it can absorb a surge in transcoding load. But it isn't working. `kubectl get hpa` shows its target as `<unknown>/50%`, and no matter the load it stays at one replica. The autoscaler is effectively dead.

The reflex is to blame the metrics pipeline, but metrics-server is installed and healthy (the baseline's `sip-router` HPA reads a real percentage, and `kubectl top pods` works). The problem is on the *target* side: the HPA is being asked to compute a percentage it has no way to compute.

Your job: read the autoscaler's own status to see why it can't get a metric, then fix the target so the HPA can do its arithmetic.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
