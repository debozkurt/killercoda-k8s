#!/bin/bash
# Checks: sip-registrar's PDB now permits at least one voluntary disruption, so the budget no
# longer blocks a drain. Asserts the outcome (allowed disruptions >= 1), not the exact edit
# (lowering minAvailable or switching to maxUnavailable both work). Waits briefly so a replacement
# Pod from the learner's eviction or cordon exercise can settle.
for i in 1 2 3 4 5 6; do
  ALLOWED=$(kubectl get pdb sip-registrar -n signaling -o jsonpath='{.status.disruptionsAllowed}' 2>/dev/null)
  [ -n "$ALLOWED" ] && [ "$ALLOWED" -ge 1 ] && break
  sleep 5
done
if [ -z "$ALLOWED" ]; then
  echo "PDB sip-registrar has no status yet, or was deleted. Confirm the budget exists, then retry." >&2
  exit 1
fi
if [ "$ALLOWED" -lt 1 ]; then
  echo "PDB sip-registrar still allows $ALLOWED disruptions. Lower minAvailable below the replica count, or uncordon the worker if you cordoned it:" >&2
  echo "  kubectl patch pdb sip-registrar -n signaling --type merge -p '{\"spec\":{\"minAvailable\":1}}'" >&2
  echo "  kubectl uncordon \$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name)" >&2
  exit 1
fi
echo "✓ PDB sip-registrar allows $ALLOWED disruption(s), so a drain can proceed"
exit 0
