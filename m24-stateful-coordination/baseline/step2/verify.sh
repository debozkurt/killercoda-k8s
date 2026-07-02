#!/bin/bash
# Checks: the session-cache Service is headless (clusterIP None) — the property that
# publishes per-Pod DNS. Defensive baseline check.
CIP=$(kubectl get svc session-cache -n media -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CIP" ]; then
  echo "Service session-cache not found in media yet. Wait for the fleet to come up and retry." >&2
  exit 1
fi
if [ "$CIP" != "None" ]; then
  echo "session-cache has a clusterIP ('$CIP'), not None — it is not headless. Per-Pod DNS won't be published." >&2
  exit 1
fi
echo "✓ session-cache is headless (clusterIP: None) — per-Pod DNS is published"
exit 0
