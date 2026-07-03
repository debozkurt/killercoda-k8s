#!/bin/bash
# Checks the healthy webhook is fail-closed AND scoped: failurePolicy Fail, and the
# namespaceSelector targets the admission-guard=enabled label (tenant-apps only), so the
# fleet and control plane are outside the blast radius.
FP=$(kubectl get validatingwebhookconfiguration admission-guard -o jsonpath='{.webhooks[0].failurePolicy}' 2>/dev/null)
if [ "$FP" != "Fail" ]; then
  echo "Expected the validating webhook's failurePolicy to be Fail (the healthy baseline). Found: '${FP:-<none>}'." >&2
  exit 1
fi
SEL=$(kubectl get validatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].namespaceSelector.matchLabels.admission-guard}' 2>/dev/null)
if [ "$SEL" = "enabled" ]; then
  echo "✓ webhook is fail-closed (Fail) and scoped to namespaces labeled admission-guard=enabled (tenant-apps)"
  exit 0
fi
echo "The validating webhook's namespaceSelector doesn't scope to admission-guard=enabled — is this still the healthy baseline?" >&2
exit 1
