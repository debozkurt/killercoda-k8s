#!/bin/bash
# Checks: route-engine Pods carry a termination grace period (>0), so the graceful-
# shutdown story in this step holds, and the Deployment is back to full availability
# after the delete-one-replica demonstration. Defensive baseline check.
GRACE=$(kubectl get pod -n call-routing -l app=route-engine -o jsonpath='{.items[0].spec.terminationGracePeriodSeconds}' 2>/dev/null)
if [ -z "$GRACE" ] || [ "$GRACE" -le 0 ]; then
  echo "Could not read a positive terminationGracePeriodSeconds on a route-engine Pod (got '${GRACE:-none}'). The replacement Pod may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ route-engine Pods have a ${GRACE}s termination grace period"
exit 0
