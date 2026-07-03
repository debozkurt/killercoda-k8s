#!/bin/bash
# Checks: the admission-guard backend is Available and both webhook configurations are
# registered. Proves the raw webhook machinery is wired into the API server's write path.
AVAIL=$(kubectl get deploy admission-guard -n admission -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$AVAIL" ] || [ "$AVAIL" -lt 1 ] 2>/dev/null; then
  echo "admission-guard isn't Available yet — the python image pull can take a minute on first boot. Wait and retry." >&2
  exit 1
fi
kubectl get mutatingwebhookconfiguration admission-guard >/dev/null 2>&1 || {
  echo "MutatingWebhookConfiguration 'admission-guard' not found yet — the webhooks register after the backend is ready. Wait and retry." >&2; exit 1; }
kubectl get validatingwebhookconfiguration admission-guard >/dev/null 2>&1 || {
  echo "ValidatingWebhookConfiguration 'admission-guard' not found yet. Wait and retry." >&2; exit 1; }
echo "✓ admission-guard is running and both webhook configurations are registered"
exit 0
