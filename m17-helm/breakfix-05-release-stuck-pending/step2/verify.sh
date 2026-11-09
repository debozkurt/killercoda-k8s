#!/bin/bash
# Checks: the pending lock is cleared through Helm and the greeting shipped.
# The latest revision is deployed, the live Deployment is back on the healthy
# memory request, no voicemail Pod is Pending, and GREETING has the new text.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

STATUS=$(helm status voicemail -n app-services 2>/dev/null | awk '/^STATUS:/ {print $2}')
[ "$STATUS" = "deployed" ] || { echo "Latest voicemail revision is ${STATUS:-missing}, not deployed. Run: helm rollback voicemail 1 -n app-services" >&2; exit 1; }

MEM=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null)
[ "$MEM" = "32Mi" ] || { echo "voicemail requests ${MEM:-none} memory, expected 32Mi. Roll back to revision 1 first." >&2; exit 1; }

PENDING=$(kubectl get pods -n app-services -l app=voicemail --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
[ "$PENDING" -eq 0 ] || { echo "$PENDING voicemail Pod(s) still Pending. Wait for the rollout to finish." >&2; exit 1; }

GREETING=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="GREETING")].value}' 2>/dev/null)
[ "$GREETING" != "You have reached Polyphone voicemail." ] && [ -n "$GREETING" ] \
  || { echo "GREETING still has the old text. Run the greeting upgrade from step 2." >&2; exit 1; }

echo "✓ Lock cleared: revision deployed, 32Mi request, no Pending Pods, new greeting shipped"
exit 0
