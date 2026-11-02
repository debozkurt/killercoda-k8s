# M13 — Break/fix 02: a sidecar that dies after it starts

> Pre-req: the M13 baseline tour. In step 5 you read a container that had died with `--previous`. Here it is the whole diagnosis.

`sip-monitor` in the `signaling` namespace runs the SIP monitoring app next to a telemetry **sidecar**, a second container in the same Pod that exports the app's metrics. The app serves traffic. `kubectl get pods` reads 1/2, the restart count climbs, and nobody was paged. One of the two containers is down. Until you find which one and why, that workload's telemetry is dark.

Your job: name the container that is not Ready, read the instance that died to learn why, and fix it until the Pod reaches 2/2 and the sidecar exports telemetry.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
