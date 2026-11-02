#!/bin/bash
# Checks: the healthy application-metrics target is present, its scrape port
# annotation matches the port it serves on (80), and its Service has endpoints.
# Defensive baseline check: nothing is broken.
if ! kubectl get deployment call-metrics -n analytics >/dev/null 2>&1; then
  echo "call-metrics is not present in namespace analytics yet. The cluster may still be coming up." >&2
  echo "  Wait 30 seconds, then run: kubectl get pods -n analytics" >&2
  exit 1
fi
PORT=$(kubectl get deploy call-metrics -n analytics \
  -o jsonpath='{.spec.template.metadata.annotations.prometheus\.io/port}' 2>/dev/null)
if [ "$PORT" != "80" ]; then
  echo "call-metrics has prometheus.io/port='$PORT', expected '80' (the port it serves /metrics on)." >&2
  echo "  Inspect it with: kubectl describe pod -n analytics -l app=call-metrics" >&2
  exit 1
fi
EP=$(kubectl get endpoints call-metrics -n analytics -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ -z "$EP" ]; then
  echo "The Service call-metrics has no endpoints yet. Its Pod may still be starting." >&2
  echo "  Check it with: kubectl describe service call-metrics -n analytics" >&2
  exit 1
fi
echo "✓ call-metrics is a healthy scrape target: port 80 matches, and its Service has an endpoint"
exit 0
