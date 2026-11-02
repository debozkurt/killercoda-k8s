# M13 — Break/fix 03: a scrape target that is DOWN

> Pre-req: the M13 baseline tour. There you read a healthy `/metrics` endpoint and its `prometheus.io/*` annotations. Here the annotation and the endpoint disagree.

`call-metrics` in the `analytics` namespace publishes call metrics for Prometheus to scrape. The app is healthy: Running 1/1, and `kubectl top` shows normal CPU and memory. Every dashboard and alert built on its metrics has gone flat. No data arrives.

This is the two-pipelines distinction. The resource metrics pipeline (`kubectl top`) is separate from the application metrics pipeline (Prometheus scraping `/metrics`). No Prometheus runs in this lab, so you play the scraper with `curl`.

Your job: confirm that the app exposes its metrics, find why a scraper cannot collect them, and fix the scrape target. The app is not sick. The scrape is.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
