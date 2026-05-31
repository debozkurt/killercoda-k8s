#!/bin/bash
# Checks: session-broker's terminationGracePeriodSeconds now exceeds the 15s
# preStop drain (so the drain can finish before SIGKILL), and it rolled out.
GRACE=$(kubectl get deploy session-broker -n media -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}' 2>/dev/null)
if [ -z "$GRACE" ] || [ "$GRACE" -le 15 ] 2>/dev/null; then
  echo "terminationGracePeriodSeconds is '$GRACE'; the preStop drain needs 15s, so set it higher (e.g. 30):" >&2
  echo "  kubectl patch deployment session-broker -n media -p '{\"spec\":{\"template\":{\"spec\":{\"terminationGracePeriodSeconds\":30}}}}'" >&2
  exit 1
fi

AVAIL=$(kubectl get deploy session-broker -n media -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ -n "$AVAIL" ] && [ "$AVAIL" -ge 1 ] 2>/dev/null || { echo "session-broker has $AVAIL available replicas; the rollout may still be in flight — re-check in a few seconds" >&2; exit 1; }

echo "✓ Grace period sized for the drain: ${GRACE}s > 15s preStop, session-broker available with $AVAIL replica(s)"
exit 0
