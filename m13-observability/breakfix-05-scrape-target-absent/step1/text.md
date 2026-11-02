# Step 1 — Diagnose the missing target

A DOWN target has an address that refuses a connection. An absent target has no address. Check the address list before the port.

## The app is healthy

```bash
kubectl get pods -n analytics -l app=call-metrics
kubectl top pod -n analytics -l app=call-metrics
```{{exec}}

The Pod is Running 1/1 and `kubectl top` returns CPU and memory. Both pipelines see a healthy app.

## What does the Service list?

A **Service** keeps a list of **endpoints**: the addresses of the Pods whose labels match its selector. A service-based scraper reads that list.

```bash
kubectl describe service call-metrics -n analytics | grep -E "Selector|Endpoints"
```{{exec}}

```text
Selector:  app=call-metric
Endpoints: <none>
```

Endpoints is none. The selector reads `call-metric`, without the final s. Compare it with the Pod's label:

```bash
kubectl get pods -n analytics -l app=call-metrics --show-labels
```{{exec}}

The Pod carries `app=call-metrics`. The selector matches no Pod, so the Service has no endpoints. A scraper finds no target. Prometheus shows no DOWN row and records no `up` series, so an alert on `up == 0` has nothing to evaluate.

## Rule out the port

The port is the other common cause, so confirm it is fine:

```bash
kubectl describe pod -n analytics -l app=call-metrics | grep -E "prometheus.io|Port:"
POD_IP=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].status.podIP}')
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$POD_IP:80/metrics
```{{exec}}

The annotation prometheus.io/port names 80, the container port, and the call returns HTTP 200. Break/fix 03's cause is absent. The Service is the fault. On to the fix.
