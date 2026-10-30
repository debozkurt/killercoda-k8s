#!/bin/bash
# Checks: the healthy PDB on route-engine reports at least one allowed disruption, after the
# eviction exercise in this step. Defensive baseline check; the evicted Pod's replacement may
# still be starting, so allow a short settle.
for i in 1 2 3 4 5 6; do
  ALLOWED=$(kubectl get pdb route-engine -n call-routing -o jsonpath='{.status.disruptionsAllowed}' 2>/dev/null)
  [ -n "$ALLOWED" ] && [ "$ALLOWED" -ge 1 ] && break
  sleep 5
done
if [ -z "$ALLOWED" ]; then
  echo "PDB route-engine has no status yet. The disruption controller may still be computing it. Wait a few seconds and retry." >&2
  exit 1
fi
if [ "$ALLOWED" -lt 1 ]; then
  echo "PDB route-engine reports ALLOWED DISRUPTIONS $ALLOWED (expected at least 1). The replacement Pod may still be starting. Run:" >&2
  echo "  kubectl wait --for=condition=Ready pod -l app=route-engine -n call-routing --timeout=60s" >&2
  exit 1
fi
echo "✓ PDB route-engine allows $ALLOWED disruption(s)"
exit 0
