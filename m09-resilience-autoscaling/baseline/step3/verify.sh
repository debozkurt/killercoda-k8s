#!/bin/bash
# Checks: the healthy PDB on route-engine reports at least one allowed disruption,
# so the "budget with headroom" story in this step holds. Defensive baseline check.
ALLOWED=$(kubectl get pdb route-engine -n call-routing -o jsonpath='{.status.disruptionsAllowed}' 2>/dev/null)
if [ -z "$ALLOWED" ]; then
  echo "PDB route-engine has no status yet — the disruption controller may still be computing it. Wait a few seconds and retry." >&2
  exit 1
fi
if [ "$ALLOWED" -lt 1 ]; then
  echo "PDB route-engine reports ALLOWED DISRUPTIONS $ALLOWED (expected >= 1). Confirm route-engine has 2 healthy replicas and minAvailable is 1." >&2
  exit 1
fi
echo "✓ PDB route-engine allows $ALLOWED disruption(s) — headroom for a safe drain"
exit 0
