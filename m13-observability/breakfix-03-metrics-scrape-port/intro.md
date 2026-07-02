# M13 — Break/fix 03: Metrics — a scrape target that's DOWN

> Pre-req: the M13 baseline tour. You've read a healthy `/metrics` endpoint and its `prometheus.io/*` scrape annotations; here the two don't line up.

`call-metrics` in the `analytics` namespace publishes fleet call metrics for Prometheus to scrape. The app is healthy — `Running 1/1`, `kubectl top` shows it using CPU and memory like normal — but every dashboard and alert built on its metrics has gone flat. No data is arriving.

This is the two-pipelines distinction made concrete: the **resource metrics** pipeline (`kubectl top`) is fine, because it's separate from the **application metrics** pipeline (Prometheus scraping `/metrics`). Your job: confirm the app really is exposing metrics, then find why a scraper can't collect them — and fix the scrape target so it's reachable. The app is not sick; the scrape is.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
