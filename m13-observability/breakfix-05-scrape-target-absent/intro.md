# M13 — Break/fix 05: a scrape target that is absent

> Pre-req: break/fix 03. There a wrong port made the target DOWN. Here the port is right and the target is missing.

`call-metrics` in the `analytics` namespace publishes call metrics. The app is healthy: Running 1/1, `kubectl top` works, and `/metrics` answers on its port. The scrape annotations are correct. Every dashboard built on it is flat, and the alert on `up == 0` stays silent. Prometheus does not list a DOWN target for it. It lists no target at all.

Your platform's monitoring discovers targets through Services. A **ServiceMonitor** selects a Service by label and scrapes the endpoints behind it. If the Service has no endpoints, the scraper finds nothing to scrape.

Your job: check what the Service lists, find why it lists no endpoints, rule out the port, and fix it. No Prometheus runs in this lab.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
