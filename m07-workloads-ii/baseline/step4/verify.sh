#!/bin/bash
# Checks: sbc-edge covers both nodes (desiredNumberScheduled == 2), proving the
# control-plane toleration makes the tainted node eligible. Defensive baseline check.
DESIRED=$(kubectl get ds sbc-edge -n edge -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
if [ "$DESIRED" != "2" ]; then
  echo "Expected sbc-edge DESIRED 2 (one Pod per node), got '$DESIRED'. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ sbc-edge covers both nodes (DESIRED 2) — its control-plane toleration makes the tainted node eligible"
exit 0
