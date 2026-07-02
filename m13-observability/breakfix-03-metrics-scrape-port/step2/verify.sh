#!/bin/bash
# Checks: the scrape port annotation now matches the port the container serves
# /metrics on, so the scrape target is reachable. Deterministic field check —
# compares prometheus.io/port against the container's declared port.
PORT=$(kubectl get deploy call-metrics -n analytics \
  -o jsonpath='{.spec.template.metadata.annotations.prometheus\.io/port}' 2>/dev/null)
CPORT=$(kubectl get deploy call-metrics -n analytics \
  -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}' 2>/dev/null)
if [ -z "$PORT" ] || [ -z "$CPORT" ]; then
  echo "Couldn't read call-metrics' scrape port or container port — is the workload present in analytics?" >&2
  exit 1
fi
if [ "$PORT" != "$CPORT" ]; then
  echo "The scrape port still doesn't match: prometheus.io/port='$PORT' but the container serves on '$CPORT'. Set prometheus.io/port to '$CPORT' (the port /metrics is served on), e.g. kubectl patch deployment call-metrics -n analytics -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"prometheus.io/port\":\"$CPORT\"}}}}}'" >&2
  exit 1
fi
echo "✓ prometheus.io/port ($PORT) matches the container's serving port ($CPORT) — the scrape target is reachable again"
exit 0
