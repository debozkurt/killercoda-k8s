# Step 4 — Application metrics: the scrape model

The second pipeline is **application metrics**: a workload publishes numbers about *itself* at an HTTP `/metrics` endpoint, and Prometheus **pulls** (scrapes) it on an interval. `call-metrics` in `analytics` is a healthy example.

## Read the exposition endpoint

```bash
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s call-metrics/metrics
```{{exec}}

That's the **exposition format** — plain text, one `name{labels} value` per line, with `# HELP`/`# TYPE` headers. Note the metric *types*: `sip_calls_active` is a **gauge** (goes up and down), `sip_calls_total` is a **counter** (only climbs — you `rate()` it), `sip_call_setup_seconds` is a **histogram** (buckets, for percentiles).

## How a scraper finds it: the annotations

```bash
kubectl get pod -n analytics -l app=call-metrics \
  -o jsonpath='{.items[0].metadata.annotations}'; echo
```{{exec}}

```text
prometheus.io/scrape: "true"   prometheus.io/port: "80"   prometheus.io/path: "/metrics"
```

These are the lightweight discovery convention: a Prometheus scrapes every Pod annotated `scrape: "true"` at the given `port` and `path`. The production alternative is the **Prometheus Operator**, where you declare a **ServiceMonitor** custom resource instead ("scrape every Pod behind this Service, on the port named `metrics`").

## The load-bearing detail: the port must match

The `prometheus.io/port` (or the ServiceMonitor's port) must be the port the workload *actually* serves `/metrics` on. Here it's `80`, and the container listens on `80`:

```bash
kubectl get pod -n analytics -l app=call-metrics \
  -o jsonpath='{.items[0].spec.containers[0].ports}'; echo
```{{exec}}

Both `80` — the target is scrapeable. If they disagree, the scrape is refused, the target shows **DOWN**, and every graph for this workload goes flat while the app stays healthy and `kubectl top` still works — a different pipeline, a different failure. You'll break exactly that in break/fix 03.

That's all three built-in signals. Read `finish.md`, then work the break/fix scenarios.
