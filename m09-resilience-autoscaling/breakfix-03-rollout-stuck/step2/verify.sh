#!/bin/bash
# Checks: portal-web is off the bad image and fully rolled out — every replica updated
# and available. Asserts the outcome (a healthy, complete rollout on a good image), not
# the exact fix (rollout undo is canonical; rolling forward to a valid tag also passes).
IMG=$(kubectl get deployment portal-web -n admin-portal -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
DESIRED=$(kubectl get deployment portal-web -n admin-portal -o jsonpath='{.spec.replicas}' 2>/dev/null)
UPDATED=$(kubectl get deployment portal-web -n admin-portal -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)
AVAIL=$(kubectl get deployment portal-web -n admin-portal -o jsonpath='{.status.availableReplicas}' 2>/dev/null)

if [ "$IMG" = "nginx:1.25-doesnotexist" ]; then
  echo "portal-web is still on the bad image ($IMG). Roll back with 'kubectl rollout undo deployment/portal-web -n admin-portal' (or roll forward to a valid tag)." >&2
  exit 1
fi
if [ -z "$UPDATED" ] || [ "$UPDATED" != "$DESIRED" ] || [ "$AVAIL" != "$DESIRED" ]; then
  echo "portal-web rollout is not complete yet (updated ${UPDATED:-0}/${DESIRED:-?}, available ${AVAIL:-0}/${DESIRED:-?}). Wait for 'kubectl rollout status' to report success and retry." >&2
  exit 1
fi
echo "✓ portal-web fully rolled out on '$IMG' ($UPDATED/$DESIRED updated, $AVAIL/$DESIRED available)"
exit 0
