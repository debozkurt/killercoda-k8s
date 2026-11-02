# Done

You read the three built-in signals on a healthy fleet.

- **Events**: the stream with `kubectl events`, filtered by type, scoped with `--for`, and the older `get events --field-selector`.
- **Logs**: `kubectl logs` with `--tail`, `--since` and `--previous`, and the stdout-only contract.
- **Resource metrics**: `kubectl top` against a request.
- **Application metrics**: a `/metrics` endpoint, its annotations, and the Service endpoints behind it.
- **Restarts**: a clean current log, the crash in `--previous`, and the logs that left with the Pod.

**Next:**

- Read [`LESSON.md`](../LESSON.md) for the why: the three questions, the ephemerality, the two metrics pipelines and where traces fit.
- Work the five break/fix scenarios in order. Each breaks the reading of one signal:
  - **`breakfix-01-logs-to-stdout`**: a Pod is Running 1/1 and its log holds one line. The app writes to a file.
  - **`breakfix-02-sidecar-crashloop`**: a Pod reads 1/2. A telemetry sidecar dies after it starts. Read the instance that died.
  - **`breakfix-03-metrics-scrape-port`**: the app is healthy and the dashboards are flat. The scrape port is wrong, so the target is DOWN.
  - **`breakfix-04-event-only-failure`**: a workload never starts and has no logs. Only an event names the cause.
  - **`breakfix-05-scrape-target-absent`**: the dashboards are flat and the port is right. The Service has no endpoints, so the target is absent.
- Check each path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
