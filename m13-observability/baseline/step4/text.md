# Step 4 — Application metrics: the scrape model

The second pipeline is **application metrics**. A workload publishes numbers about itself at an HTTP `/metrics` endpoint. **Prometheus**, a time-series database, pulls (scrapes) that endpoint on an interval. `call-metrics` in `analytics` is a healthy example.

## Read the endpoint

```bash
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s call-metrics/metrics
```{{exec}}

This is the **exposition format**: plain text with one `name{labels} value` line per sample, and `# HELP` and `# TYPE` headers. Three metric types appear:

- `sip_calls_active` is a **gauge**. It rises and falls.
- `sip_calls_total` is a **counter**. It only rises, so you read its rate.
- `sip_call_setup_seconds` is a **histogram**. It counts observations in buckets, for percentiles.

## How a scraper finds it

```bash
kubectl describe pod -n analytics -l app=call-metrics | grep -E "prometheus.io|Port:"
```{{exec}}

Three annotations name the scrape: prometheus.io/scrape, prometheus.io/port and prometheus.io/path. The Port line shows the container port, named metrics.

These annotations are a community convention. Kubernetes and Prometheus ignore them unless the scrape configuration reads them. No Prometheus runs in this lab. In the break/fix labs you play the scraper with `curl`.

## Check the Service

A **Service** gives Pods one stable address and lists the Pods it selects as **endpoints**. A ServiceMonitor, the Prometheus Operator's scrape object, finds targets through those endpoints:

```bash
kubectl describe service call-metrics -n analytics | grep -E "Selector|Port|Endpoints"
```{{exec}}

The Selector matches the Pod's label, and Endpoints lists the Pod's address. Two things must hold for a scrape to succeed: the Service must have endpoints, and the advertised port must match the port the app serves. Break/fix 03 breaks the second. Break/fix 05 breaks the first.

Next: the last signal is a container that already died.
