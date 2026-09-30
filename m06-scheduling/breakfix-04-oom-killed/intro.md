# M06 — Break/fix 04: OOMKilled

> Pre-req: breakfix-01 through 03. All three Pods were `Pending`, and the scheduler refused each one. This Pod schedules without trouble.

A new media workload, `media-buffer`, allocates an in-memory jitter buffer at startup. It rolled out to the `media` namespace. Unlike the last three scenarios, its Pod gets a node, but it does not stay up. `kubectl get pods` shows it cycling through `CrashLoopBackOff`, with the restart count climbing.

This is the other half of the resource contract. The scheduler placed the Pod by its request. The kernel kills the container for going over its limit. Requests are what you fit, and limits are what kill you.

Your job: read the container's last state, confirm what killed it, and give it a memory limit it can live under. Do not change what the application does.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
