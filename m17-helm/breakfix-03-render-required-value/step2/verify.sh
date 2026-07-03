#!/bin/bash
# Checks: supplying the required value let the release install — voicemail is
# deployed, its pods are Running, and SIP_REALM rendered into the container env.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

helm status voicemail -n app-services 2>/dev/null | grep -q '^STATUS: deployed' \
  || { echo "voicemail release is not deployed — was the required value supplied?" >&2; exit 1; }

READY=$(kubectl get pods -n app-services -l app=voicemail --no-headers 2>/dev/null | awk '$3 == "Running"' | wc -l)
[ "$READY" -ge 2 ] || { echo "Expected 2 voicemail pods Running, got $READY" >&2; exit 1; }

REALM=$(kubectl get deployment voicemail -n app-services \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="SIP_REALM")].value}' 2>/dev/null)
[ -n "$REALM" ] || { echo "SIP_REALM env is empty on the voicemail container — required value not rendered" >&2; exit 1; }

echo "✓ Required value supplied: voicemail deployed, $READY pods Running, SIP_REALM=$REALM"
exit 0
