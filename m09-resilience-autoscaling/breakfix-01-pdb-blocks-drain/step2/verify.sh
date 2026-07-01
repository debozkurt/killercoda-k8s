#!/bin/bash
# Checks: sip-registrar's PDB now permits at least one voluntary disruption, so a drain
# is no longer blocked by the budget. Asserts the outcome (allowed disruptions >= 1),
# not the exact edit (lowering minAvailable or switching to maxUnavailable both work).
ALLOWED=$(kubectl get pdb sip-registrar -n signaling -o jsonpath='{.status.disruptionsAllowed}' 2>/dev/null)
if [ -z "$ALLOWED" ]; then
  echo "PDB sip-registrar has no status yet (or was deleted). Confirm the budget exists and the disruption controller has computed it, then retry." >&2
  exit 1
fi
if [ "$ALLOWED" -lt 1 ]; then
  echo "PDB sip-registrar still allows $ALLOWED disruptions. Lower minAvailable below the replica count (e.g. minAvailable: 1, or use maxUnavailable: 1) so ALLOWED DISRUPTIONS is at least 1." >&2
  exit 1
fi
echo "✓ PDB sip-registrar now allows $ALLOWED disruption(s) — a drain can proceed"
exit 0
