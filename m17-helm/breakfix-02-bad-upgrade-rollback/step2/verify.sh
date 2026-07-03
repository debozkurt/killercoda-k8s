#!/bin/bash
# Checks: the release was rolled back through Helm — image restored to the good
# tag, rollout complete (no stuck pods), and the release advanced to a new
# deployed revision (proves the fix went through Helm, not a bare kubectl edit).
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

IMG=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$IMG" = "nginx:1.25" ] || { echo "Expected image nginx:1.25 after rollback, got ${IMG:-none}" >&2; exit 1; }

# No voicemail pods stuck pulling the bad image.
BAD=$(kubectl get pods -n app-services -l app=voicemail --no-headers 2>/dev/null | grep -cE "ImagePullBackOff|ErrImagePull")
[ "$BAD" -eq 0 ] || { echo "Still $BAD voicemail pod(s) failing to pull the image" >&2; exit 1; }

# Rollout complete: updated == desired == available.
DESIRED=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
UPDATED=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)
AVAIL=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ "$UPDATED" = "$DESIRED" ] && [ "$AVAIL" = "$DESIRED" ] \
  || { echo "Rollout not complete: desired=$DESIRED updated=${UPDATED:-0} available=${AVAIL:-0}" >&2; exit 1; }

# Recovery went through Helm (revision advanced past the broken rev 2).
REV=$(helm status voicemail -n app-services 2>/dev/null | awk '/^REVISION:/ {print $2}')
[ -n "$REV" ] && [ "$REV" -ge 3 ] || { echo "Expected release revision >= 3 (rolled back via Helm), got ${REV:-none}" >&2; exit 1; }

echo "✓ Rolled back via Helm: image $IMG, rollout complete ($AVAIL/$DESIRED), release now revision $REV"
exit 0
