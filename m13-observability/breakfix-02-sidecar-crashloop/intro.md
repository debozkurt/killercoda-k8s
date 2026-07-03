# M13 — Break/fix 02: Logs & Events — a crashlooping sidecar

> Pre-req: the M13 baseline tour. You've read the event stream and used `kubectl logs` with `-c` and `--previous`; here they're the whole diagnosis.

`sip-monitor` in the `signaling` namespace runs the SIP monitoring app alongside a telemetry **sidecar** that exports its metrics. The Pod is up, the app is serving — but `kubectl get pods` shows it `1/2`, and nobody was paged. One of its two containers is down, and until you find out which one and why, that workload's telemetry is dark.

Your job: read the Pod's containers to see *which* one isn't Ready, use the event stream and the failing container's own logs — the ones from the instance that already died — to find out why it keeps exiting, and fix it so the Pod reaches `2/2`. This is `-c` and `--previous` doing real work.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
