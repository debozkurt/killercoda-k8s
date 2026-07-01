#!/bin/bash
# Checks: all 3 sip-director replicas are now available — the spread rule no longer
# wedges the surplus replicas. Asserts the outcome, not the exact fix chosen
# (soften to preferred is canonical; scaling to 1 replica is also accepted).
AVAIL=$(kubectl get deploy sip-director -n signaling -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
DESIRED=$(kubectl get deploy sip-director -n signaling -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ -z "$AVAIL" ] || [ "$AVAIL" != "$DESIRED" ]; then
  echo "sip-director is not fully available (${AVAIL:-0}/${DESIRED:-?}). Soften the required anti-affinity to preferred so the replicas can schedule (or scale replicas to fit the schedulable nodes)." >&2
  exit 1
fi
echo "✓ sip-director is fully available ($AVAIL/$DESIRED) — no replica is stuck Pending"
exit 0
