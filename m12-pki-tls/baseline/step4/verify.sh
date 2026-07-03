#!/bin/bash
# Checks: the leaf Certificate carries a validity window and a scheduled renewal.
# Defensive baseline check — nothing is broken.
NOTAFTER=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.status.notAfter}' 2>/dev/null)
RENEWAL=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.status.renewalTime}' 2>/dev/null)
if [ -z "$NOTAFTER" ]; then
  echo "config-api-tls has no notAfter yet — it may still be issuing. Wait and retry." >&2
  exit 1
fi
if [ -z "$RENEWAL" ]; then
  echo "config-api-tls has no renewalTime yet — cert-manager schedules it shortly after issuance. Wait and retry." >&2
  exit 1
fi
echo "✓ config-api-tls expires at $NOTAFTER and cert-manager will auto-renew at $RENEWAL"
exit 0
