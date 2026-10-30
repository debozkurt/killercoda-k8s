# M09 — Break/fix 02: HPA Can't Read Its Metric

> Pre-req: the baseline tour. You saw a healthy HPA read CPU utilization as a percentage of the container's request. This one cannot.

`transcode-scaler` in `media` autoscales on CPU, from 1 to 5 replicas at a 50% target. It does not work. `kubectl get hpa` shows `<unknown>/50%`, and the replica count stays at 1 under any load.

The reflex is to blame the metrics pipeline. metrics-server is healthy here, and `kubectl top pods -n media` returns live CPU. The fault is on the target side.

Your job: read the autoscaler's own status to see why it has no metric, then fix the target so the HPA can compute a percentage.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
