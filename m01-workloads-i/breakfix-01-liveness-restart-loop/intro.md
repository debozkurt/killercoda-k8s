# M01 — Break/fix 01: Liveness Restart Loop

> Pre-req: the M01 baseline tour, or comfort with `kubectl get/describe/logs` and the idea that a liveness probe restarts a container.

You're on call. An alert fires: **`route-engine` in `call-routing` is in `CrashLoopBackOff`.** Call-routing decisions are degraded — calls are landing on whichever replica happens to be up between restarts.

`CrashLoopBackOff` *sounds* like the application is crashing. Sometimes it is. Sometimes the application is perfectly healthy and something else is killing it on a timer. Your job is to tell which, then fix the real cause — not to paper over it.

The fix is one field. The skill is the diagnosis: knowing where to look to separate "the app died" from "something restarted a living app," so you don't waste an incident debugging code that was never broken.

The cluster takes 60–120 seconds to come up; the restart loop needs another ~30 seconds to show a climbing restart count. Click **Start** when ready.
