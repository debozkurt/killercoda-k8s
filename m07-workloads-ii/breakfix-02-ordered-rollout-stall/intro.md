# M07 — Break/fix 02: Ordered Rollout Stall

> Pre-req: breakfix-01. You've seen a StatefulSet whose Pods were all there but unreachable; this one is the opposite — the Pods aren't all there.

The same `session-store` StatefulSet was declared with **3 replicas**, and this time its governing headless Service is in place. But the rollout never finished: `kubectl get statefulset` reports `READY 0/3`, and only a single Pod, `session-store-0`, exists — `Running`, but not Ready. `session-store-1` and `session-store-2` were never created.

A Deployment asked for 3 replicas would have created all 3 at once, and two healthy Pods would be serving despite the third being sick. A StatefulSet doesn't work that way. Your job: figure out why `session-store-0` won't go Ready, and understand why that single un-ready Pod is the reason the other two don't exist at all.

This is the ordered-lifecycle guarantee showing its teeth. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
