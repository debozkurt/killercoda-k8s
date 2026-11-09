#!/bin/bash
# Checks: the release was recovered through Helm. The latest revision is
# deployed and newer than the bad revision 2, its stored manifest carries the
# good image, the live Deployment runs that image, and the rollout is complete.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

STATUS=$(helm status voicemail -n app-services 2>/dev/null | awk '/^STATUS:/ {print $2}')
REV=$(helm status voicemail -n app-services 2>/dev/null | awk '/^REVISION:/ {print $2}')
[ "$STATUS" = "deployed" ] && [ "${REV:-0}" -ge 3 ] \
  || { echo "Expected a deployed revision >= 3, got ${STATUS:-none} revision ${REV:-none}. Run: helm rollback voicemail 1 -n app-services" >&2; exit 1; }

STORED=$(helm get manifest voicemail -n app-services 2>/dev/null | awk '/image:/ {gsub(/"/,"",$2); print $2; exit}')
LIVE=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$STORED" = "nginx:1.25" ] || { echo "The release manifest still runs ${STORED:-none}. Recover through Helm, not kubectl." >&2; exit 1; }
[ "$LIVE" = "$STORED" ] || { echo "Live image $LIVE differs from the release manifest $STORED" >&2; exit 1; }

DESIRED=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
UPDATED=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)
AVAIL=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
BAD=$(kubectl get pods -n app-services -l app=voicemail --no-headers 2>/dev/null | grep -cE 'ImagePullBackOff|ErrImagePull')
[ "$UPDATED" = "$DESIRED" ] && [ "$AVAIL" = "$DESIRED" ] && [ "$BAD" -eq 0 ] \
  || { echo "Rollout not complete: desired=$DESIRED updated=${UPDATED:-0} available=${AVAIL:-0} pull-failures=$BAD. Wait and check again." >&2; exit 1; }

echo "✓ Recovered through Helm: revision $REV deployed, image $LIVE, rollout complete ($AVAIL/$DESIRED)"
exit 0
