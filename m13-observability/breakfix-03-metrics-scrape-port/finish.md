# Done

The dashboards were flat and the app was healthy. The resource pipeline worked: `kubectl top` returned data. The app served `/metrics` on port 80. The Pod's `prometheus.io/port` annotation advertised 9090, where nothing listens. A scraper that follows the annotation gets a refused connection and marks the target **DOWN**. Pointing the annotation at port 80 fixed it.

The reflex: **flat dashboards with a healthy `kubectl top` mean a scrape problem, not a sick app.** Prove the app exposes `/metrics` on its real port. Then compare that port with the port the scrape configuration advertises, here the annotation. A one-digit mismatch removes a workload from monitoring without any error on the app.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § Metrics.
- Next scenario: **`breakfix-04-event-only-failure`**, a workload that never starts and has no logs.
