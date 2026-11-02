# Step 2 — Fix it and verify

Point the annotation at the port the container serves.

## Correct the scrape port

```bash
kubectl patch deployment call-metrics -n analytics -p \
  '{"spec":{"template":{"metadata":{"annotations":{"prometheus.io/port":"80"}}}}}'
```{{exec}}

The annotation lives in the Pod template, so the Deployment starts a new Pod that advertises the right port.

## Roll out and verify

```bash
kubectl rollout status deployment call-metrics -n analytics --timeout=60s
POD_IP=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].status.podIP}')
kubectl describe pod -n analytics -l app=call-metrics | grep prometheus.io/port
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$POD_IP:80/metrics
```{{exec}}

The annotation reads 80 and the call returns HTTP 200. A scraper that follows the annotation now gets the metrics, the target is UP, and the dashboards refill. The app never changed. Its advertised port did. Read `finish.md`, then check `ANSWER-KEY.md`.
