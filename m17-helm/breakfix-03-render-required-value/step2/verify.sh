#!/bin/bash
# Checks: the release installed once the required value was supplied. It is
# deployed, 2 Pods are ready, and SIP_REALM rendered into the container env.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

helm status voicemail -n app-services 2>/dev/null | grep -q '^STATUS: deployed' \
  || { echo "voicemail release is not deployed. Install it with --set config.sipRealm=polyphone.example" >&2; exit 1; }

READY=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" -ge 2 ] || { echo "Expected 2 ready voicemail Pods, got ${READY:-0}. Wait a few seconds and check again." >&2; exit 1; }

REALM=$(kubectl get deployment voicemail -n app-services \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="SIP_REALM")].value}' 2>/dev/null)
[ -n "$REALM" ] || { echo "SIP_REALM is empty on the voicemail container" >&2; exit 1; }

echo "✓ Required value supplied: voicemail deployed, $READY Pods ready, SIP_REALM=$REALM"
exit 0
