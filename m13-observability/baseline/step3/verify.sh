#!/bin/bash
# Checks: the Resource Metrics pipeline is installed (metrics-server present).
# kubectl top may lag 30-60s after startup, so we check the deployment exists
# rather than requiring live data. Defensive baseline check.
if ! kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
  echo "metrics-server isn't present in kube-system yet — the resource-metrics pipeline that powers 'kubectl top' isn't up. Wait for the cluster to settle and retry." >&2
  exit 1
fi
echo "✓ metrics-server is installed — the pipeline behind 'kubectl top' and the HPA is up (top may take ~30s to report data)"
exit 0
