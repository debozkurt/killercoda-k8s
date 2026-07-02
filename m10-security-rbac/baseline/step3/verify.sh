#!/bin/bash
# Checks: session-broker has a running Pod to read a securityContext from.
# Defensive baseline check.
READY=$(kubectl get deploy session-broker -n media -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$READY" != "1" ]; then
  echo "session-broker isn't Available yet (availableReplicas='$READY'). The fleet may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ session-broker is running — a fleet Pod carrying the permissive default securityContext"
exit 0
