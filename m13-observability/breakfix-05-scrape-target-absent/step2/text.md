# Step 2 — Fix it and verify

Correct the Service's selector so it matches the Pod's label.

## Patch the selector

```bash
kubectl patch service call-metrics -n analytics -p '{"spec":{"selector":{"app":"call-metrics"}}}'
```{{exec}}

A Service is not a Pod template, so nothing rolls. The endpoints fill in within a second.

## Verify

```bash
kubectl describe service call-metrics -n analytics | grep -E "Selector|Endpoints"
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s -o /dev/null -w "HTTP %{http_code}\n" http://call-metrics/metrics
```{{exec}}

Endpoints now lists the Pod's address, and a call through the Service name returns HTTP 200. A ServiceMonitor can find the target. The app never changed. The Service pointed at nothing. Read `finish.md`, then check `ANSWER-KEY.md`.
