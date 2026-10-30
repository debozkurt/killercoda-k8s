#!/bin/bash
# Checks: caption-engine has all its replicas available (the quota no longer caps it below the
# HPA minimum). Asserts the outcome (available == desired, at least 4), not the exact edit.
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  AVAIL=$(kubectl get deploy caption-engine -n captions -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  DESIRED=$(kubectl get deploy caption-engine -n captions -o jsonpath='{.spec.replicas}' 2>/dev/null)
  [ -n "$AVAIL" ] && [ "$AVAIL" = "$DESIRED" ] && [ "$AVAIL" -ge 4 ] && break
  sleep 5
done
if [ -z "$AVAIL" ] || [ "$AVAIL" != "$DESIRED" ] || [ "$AVAIL" -lt 4 ]; then
  echo "caption-engine has ${AVAIL:-0}/${DESIRED:-?} available replicas. Raise the namespace quota, then nudge the ReplicaSet:" >&2
  echo "  kubectl patch resourcequota pod-cap -n captions --type merge -p '{\"spec\":{\"hard\":{\"pods\":\"10\"}}}'" >&2
  echo "  kubectl rollout restart deployment/caption-engine -n captions" >&2
  exit 1
fi
echo "✓ caption-engine is $AVAIL/$DESIRED available, so the quota no longer caps the HPA"
exit 0
