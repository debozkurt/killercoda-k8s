# M13 — Baseline tour

A running cluster gives you three signals. Each answers one question:

- **Events** show what the control plane did.
- **Logs** show what the process said.
- **Metrics** show how much the workload uses.

This tour runs on the full Polyphone fleet on a 2-node cluster. It adds two workloads in the `analytics` namespace: `call-metrics`, a healthy application-metrics target, and `restart-demo`, a Pod that restarted once during setup. Nothing is broken. You learn to read each signal while it is healthy, so a dark signal stands out later.

Five short steps:

1. **Events**: read the event stream with `kubectl events`
2. **Logs**: `kubectl logs` and the stdout contract
3. **Resource metrics**: `kubectl top`
4. **Application metrics**: a `/metrics` endpoint and its Service
5. **Restarts**: read a container that already died, then watch logs disappear with the Pod

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
