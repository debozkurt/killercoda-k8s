#!/bin/bash
# Checks: session-cache is headless again (clusterIP None), so per-Pod DNS is
# published and peers can resolve a named member. Asserts the outcome.
CIP=$(kubectl get svc session-cache -n media -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CIP" ]; then
  echo "Service session-cache not found in media. Recreate it headless (clusterIP: None) with the same name and selector." >&2
  exit 1
fi
if [ "$CIP" != "None" ]; then
  echo "session-cache still has a clusterIP ('$CIP'), not None. clusterIP is immutable — delete the Service and recreate it with clusterIP: None." >&2
  exit 1
fi
echo "✓ session-cache is headless again (clusterIP: None) — per-Pod DNS is published"
exit 0
