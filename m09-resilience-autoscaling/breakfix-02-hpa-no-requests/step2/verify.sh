#!/bin/bash
# Checks: transcode-scaler's container now declares a CPU request — the denominator the
# HPA needs to compute utilization. Asserts the fix (a CPU request exists), which is the
# deterministic signal; the HPA's TARGETS flipping off <unknown> then follows once
# metrics-server reports a sample (which can lag a few seconds behind this check).
CPU=$(kubectl get deployment transcode-scaler -n media -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ -z "$CPU" ]; then
  echo "transcode-scaler still has no CPU request. Add one (e.g. kubectl set resources deployment/transcode-scaler -n media --requests=cpu=100m) so the HPA has a denominator for CPU utilization." >&2
  exit 1
fi
echo "✓ transcode-scaler now requests cpu=$CPU — the HPA can compute utilization again"
exit 0
