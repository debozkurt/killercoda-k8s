# Step 2 — Fix it and verify

The scrape annotation points at `9090`; the container serves `/metrics` on `80`. Point the annotation at the real port.

## Correct the scrape port

```bash
kubectl patch deployment call-metrics -n analytics -p \
  '{"spec":{"template":{"metadata":{"annotations":{"prometheus.io/port":"80"}}}}}'
```{{exec}}

This changes the Pod template's annotation, so the Deployment rolls a new Pod that advertises the port it actually serves on. (With the Prometheus Operator you'd fix the **ServiceMonitor's** `port` instead — same mismatch, same fix.)

## Roll and verify

```bash
kubectl rollout status deployment call-metrics -n analytics --timeout=60s
```{{exec}}

Confirm the annotation now matches the serving port, and that a scrape at the advertised port succeeds:

```bash
kubectl get deploy call-metrics -n analytics \
  -o jsonpath='{.spec.template.metadata.annotations.prometheus\.io/port}{"\n"}'
POD_IP=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].status.podIP}')
PORT=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].metadata.annotations.prometheus\.io/port}')
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$POD_IP:$PORT/metrics
```{{exec}}

`80`, and `HTTP 200` — a scraper hitting the advertised port now gets the metrics. The target is UP and the dashboards refill. The app never changed; the scrape target's declared port did. See `finish.md`, and check `ANSWER-KEY.md`.
