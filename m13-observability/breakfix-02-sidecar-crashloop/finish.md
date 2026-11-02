# Done

A 1/2 Pod paged no one. The nginx app served traffic while its telemetry **sidecar** exited 1 each time it started, because it had no COLLECTOR_ENDPOINT. `get pods` showed only the aggregate. `describe` named the container and its exit code. The BackOff event named it again. `kubectl logs -c metrics-agent --previous` showed the dead instance's fatal line. Setting the variable on the sidecar brought the Pod to 2/2.

The reflex: **N-1/N means one container is down. Name it, then read its log with `-c … --previous`.** Plain `kubectl logs` returns whichever instance exists now, and that may be a new instance that has not failed yet. `--previous` pins the one that died.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § Events and § Logs.
- Next scenario: **`breakfix-03-metrics-scrape-port`**, a healthy app with flat dashboards.
