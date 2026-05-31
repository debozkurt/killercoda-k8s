# M01 — Break/fix 03: preStop Truncation

> Pre-req: breakfix-01 and 02, or comfort with the Pod termination sequence (preStop → SIGTERM → SIGKILL, all inside the grace period).

A post-deploy report comes in: **every time `session-broker` in `media` is rolled or scaled, a handful of in-flight call sessions drop.** `session-broker` allocates media resources to live calls; when it shuts down, it's supposed to drain — hand off or finish its sessions — before exiting. Customers on those calls hear silence.

Nothing here looks broken in `kubectl get pods`. The pod is `Running`, `Ready`, serving traffic. This bug hides in the *shutdown path* — the part of a Pod's life you only exercise when you delete, roll, or scale it. That makes it the kind of issue that passes every health check and still pages you after a routine deploy.

Your job: reproduce the truncated shutdown, find why the drain is cut short, and size it correctly. The skill is reading the termination sequence and the budget that bounds it.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
