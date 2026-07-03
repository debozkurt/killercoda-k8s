#!/bin/bash
# Checks: the healthy application-metrics target is present and its scrape port
# annotation matches the port it serves on (80). Defensive baseline check —
# break/fix 03 ships this same workload with a mismatched port.
if ! kubectl get deployment call-metrics -n analytics >/dev/null 2>&1; then
  echo "call-metrics isn't present in namespace analytics yet. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
PORT=$(kubectl get deploy call-metrics -n analytics \
  -o jsonpath='{.spec.template.metadata.annotations.prometheus\.io/port}' 2>/dev/null)
if [ "$PORT" != "80" ]; then
  echo "call-metrics prometheus.io/port is '$PORT', expected '80' (the port it serves /metrics on). The baseline target should be healthy." >&2
  exit 1
fi
echo "✓ call-metrics is a healthy scrape target — prometheus.io/port=80 matches its serving port"
exit 0
