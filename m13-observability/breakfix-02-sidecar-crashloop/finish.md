# Done

A `1/2` Pod that paged no one: the nginx app served fine while its telemetry **sidecar** crashlooped, leaving that workload's metrics dark. `get pods` only showed the aggregate (`1/2`, `CrashLoopBackOff`); the per-container status and the `Warning`/`BackOff` event named the culprit — `container=metrics-agent` — and `kubectl logs -c metrics-agent --previous` showed the dead instance's error: it execed a binary the image didn't contain and exited 127. Correcting the sidecar's command brought the Pod to `2/2`.

The reflex: **`N-1/N` means one container is down — name it, then read *that* container's logs, and use `--previous` because the live instance is mid-restart and the dead one holds the error.** The event stream tells you which container; `-c` and `--previous` tell you why.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Events and § Logs.
- Next scenario: **`breakfix-03-metrics-scrape-port`** — a healthy app with flat dashboards, where the failing signal is a scrape target that's DOWN.
