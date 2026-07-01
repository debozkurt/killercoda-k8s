# M06 — Break/fix 04: OOMKilled

> Pre-req: breakfix-01 through 03 — all three `Pending`, all decided by the scheduler. This one is different: the Pod schedules just fine.

A new media workload, `media-buffer`, pre-allocates an in-memory jitter buffer at startup. It was deployed to the `media` namespace, and unlike the last three scenarios its Pod *does* get a node — but it won't stay up. `kubectl get pods` shows it cycling through `CrashLoopBackOff`, restart count climbing.

This is the other half of the resource contract. The scheduler fit the Pod using its *request*; the kernel is killing it for exceeding its *limit*. Requests are what you fit; limits are what kill you. Your job: read the container's last state, confirm what killed it, and give it a ceiling it can actually live under — without changing what the app does.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
