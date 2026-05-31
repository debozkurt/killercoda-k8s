# M01 — Baseline Tour

In M00 you learned to orient yourself on a cluster. Now you operate the thing you'll spend the rest of the curriculum operating: the **workload**.

This tour uses the healthy Polyphone fleet, with one workload — `sip-app` in `app-services` — configured as the *gold standard*: two replicas behind a Service, all three probes (liveness, readiness, startup), and graceful shutdown (a `preStop` drain inside a 30-second grace period). It's what a production-ready Deployment looks like when nothing is wrong.

Four short steps, following the life of a Pod:

1. **The owner chain** — how a Deployment becomes Pods, and what "declarative reconciliation" means when you delete one
2. **Pod lifecycle and restartPolicy** — phases, container states, and what a container exit triggers
3. **The three probes** — what each one decides, and how readiness wires into Service Endpoints
4. **Graceful shutdown** — the termination sequence, and why the grace period exists

There's nothing to fix here. The point is to *see what healthy looks like* before the breakfix scenarios show you each way it breaks.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
