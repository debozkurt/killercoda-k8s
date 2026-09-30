#!/bin/bash
# Checks: every desired sip-director replica is available, so no replica is stuck
# Pending. Asserts the outcome, not the fix chosen (soften to preferred and clear the
# old Pods is canonical; scaling to 1 replica is also accepted).
AVAIL=$(kubectl get deploy sip-director -n signaling -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
DESIRED=$(kubectl get deploy sip-director -n signaling -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ -z "$AVAIL" ] || [ "$DESIRED" = "0" ] || [ "$AVAIL" != "$DESIRED" ]; then
  echo "sip-director is not fully available (${AVAIL:-0}/${DESIRED:-?}). Soften the anti-affinity to preferred, then clear the old Pods:" >&2
  echo "  kubectl scale deployment sip-director -n signaling --replicas=0 && kubectl scale deployment sip-director -n signaling --replicas=3" >&2
  exit 1
fi
echo "✓ sip-director is fully available ($AVAIL/$DESIRED); no replica is stuck Pending"
exit 0
