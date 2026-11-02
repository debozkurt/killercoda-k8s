# Step 1 — Diagnose the flat dashboards

Flat dashboards on a healthy app point at the scrape. Prove the app is fine on the other pipeline first.

## The other pipeline works

```bash
kubectl get pods -n analytics -l app=call-metrics
kubectl top pod -n analytics -l app=call-metrics
```{{exec}}

The Pod is Running 1/1 and `kubectl top` returns CPU and memory. Metrics-server works and the app is alive.

## The app exposes `/metrics`

Call the endpoint on the port the container serves, 80. A throwaway Pod plays the scraper:

```bash
POD_IP=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].status.podIP}')
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s http://$POD_IP:80/metrics
```{{exec}}

The exposition text returns: sip_calls_active, sip_calls_total and the histogram. The data exists, so something does not collect it.

## Where does the scraper look?

```bash
kubectl describe pod -n analytics -l app=call-metrics | grep -E "prometheus.io|Port:"
```{{exec}}

The annotation prometheus.io/port names 9090. The container serves on 80. A scraper that follows these annotations calls the Pod on 9090. Do what it does:

```bash
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s -m 5 -o /dev/null -w "HTTP %{http_code}\n" http://$POD_IP:9090/metrics
```{{exec}}

The output reads HTTP 000: the connection is refused, because nothing listens on 9090. Prometheus marks this target **DOWN**, and the graphs go flat. The advertised port does not match the serving port. On to the fix.
