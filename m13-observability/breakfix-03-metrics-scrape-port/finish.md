# Done

Flat dashboards, healthy app — the two-pipelines distinction made concrete. The **resource metrics** pipeline was fine (`kubectl top` returned data), and the app's `/metrics` endpoint served perfectly on port 80. But the Pod's `prometheus.io/port` annotation advertised `9090`, where nothing listens, so a scraper hitting that port got connection-refused and marked the target **DOWN** — no data, flat graphs. Pointing the annotation at the real serving port (80) made the target reachable again.

The reflex: **a metrics gap with a healthy `kubectl top` is a scrape problem, not a sick app.** Prove the app exposes `/metrics` on its real port, then compare that port to the one the scrape config advertises (the `prometheus.io/port` annotation, or a ServiceMonitor's `port`). A one-digit mismatch silently drops the whole workload from monitoring.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why* — the two pipelines, the exposition format, and how scraping works — see [`LESSON.md`](../LESSON.md) § Metrics.
- That's all three break/fix scenarios. Re-read [`LESSON.md`](../LESSON.md) for the full mental model, including where traces (OpenTelemetry) fit.
