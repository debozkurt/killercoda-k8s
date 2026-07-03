# Step 1 — Diagnose the flat dashboards

Flat dashboards with a healthy app is the classic scrape problem. Prove the app is fine on the *other* pipeline first, then chase the scrape.

## The app is healthy — and `kubectl top` proves the other pipeline works

```bash
kubectl get pods -n analytics -l app=call-metrics
kubectl top pod -n analytics -l app=call-metrics
```{{exec}}

`Running 1/1`, and `kubectl top` returns CPU/memory. The **resource metrics** pipeline (metrics-server) is fine — so whatever's flat, it isn't a dead app or a dead metrics-server.

## The app really is exposing `/metrics`

Hit the endpoint on the port the container actually serves (80):

```bash
POD_IP=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].status.podIP}')
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s http://$POD_IP:80/metrics
```{{exec}}

There's the exposition output — `sip_calls_active`, `sip_calls_total`, the histogram. The application-metrics endpoint works. So the data exists; something isn't collecting it.

## Read the scrape annotation — where would a scraper look?

```bash
kubectl get pod -n analytics -l app=call-metrics \
  -o jsonpath='{.items[0].metadata.annotations.prometheus\.io/port}{"\n"}'
```{{exec}}

`9090`. A Prometheus discovers this Pod by its annotations and scrapes `podIP:9090/metrics` — but the container serves on `80`. Reproduce exactly what the scraper does:

```bash
POD_IP=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].status.podIP}')
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s -m 5 -o /dev/null -w "HTTP %{http_code}\n" http://$POD_IP:9090/metrics
```{{exec}}

`HTTP 000` — connection refused. Nothing listens on 9090, so the scrape fails and Prometheus marks the target **DOWN**. The metric never arrives; the graph goes flat. Root cause: the annotated scrape port (`9090`) doesn't match the port `/metrics` is served on (`80`). On to the fix.
