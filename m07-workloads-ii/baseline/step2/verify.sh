#!/bin/bash
# Checks: media-engine's governing Service is headless (clusterIP None), the
# mechanism that gives each ordinal a stable DNS record. Defensive baseline check.
CIP=$(kubectl get svc media-engine -n media -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ "$CIP" != "None" ]; then
  echo "Expected media-engine Service to be headless (clusterIP None), got '$CIP'. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ media-engine is governed by a headless Service (clusterIP None) — per-Pod DNS is served"
exit 0
