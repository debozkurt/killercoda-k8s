#!/bin/bash
# Checks: route-engine is back to full availability after the delete exercises in this step,
# and its Pods carry a positive termination grace period. Defensive baseline check.
for i in 1 2 3 4 5 6; do
  AVAIL=$(kubectl get deploy route-engine -n call-routing -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  DESIRED=$(kubectl get deploy route-engine -n call-routing -o jsonpath='{.spec.replicas}' 2>/dev/null)
  [ -n "$AVAIL" ] && [ "$AVAIL" = "$DESIRED" ] && break
  sleep 5
done
if [ -z "$AVAIL" ] || [ "$AVAIL" != "$DESIRED" ]; then
  echo "route-engine is not fully available yet (${AVAIL:-0}/${DESIRED:-?}). The replacement Pods may still be starting. Run:" >&2
  echo "  kubectl rollout status deployment/route-engine -n call-routing" >&2
  exit 1
fi
GRACE=$(kubectl get pod -n call-routing -l app=route-engine -o jsonpath='{.items[0].spec.terminationGracePeriodSeconds}' 2>/dev/null)
if [ -z "$GRACE" ] || [ "$GRACE" -le 0 ]; then
  echo "Could not read a positive terminationGracePeriodSeconds on a route-engine Pod (got '${GRACE:-none}'). Wait for the replacements and retry." >&2
  exit 1
fi
echo "✓ route-engine is back to $AVAIL/$DESIRED with a ${GRACE}s termination grace period"
exit 0
