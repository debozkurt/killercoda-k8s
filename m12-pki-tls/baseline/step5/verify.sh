#!/bin/bash
# Checks: config-api-tls was reissued (revision >= 2) and its Secret exists again.
# Defensive baseline check — nothing is broken.
if ! kubectl get secret config-api-tls -n media >/dev/null 2>&1; then
  echo "The Secret config-api-tls does not exist. Delete it and wait 5 seconds for cert-manager to rebuild it:" >&2
  echo "  kubectl delete secret config-api-tls -n media; sleep 5; kubectl get secret config-api-tls -n media" >&2
  exit 1
fi
REV=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.status.revision}' 2>/dev/null)
if [ "${REV:-0}" -lt 2 ]; then
  echo "config-api-tls is still at revision ${REV:-0}. Delete its Secret so cert-manager issues a second time:" >&2
  echo "  kubectl delete secret config-api-tls -n media" >&2
  exit 1
fi
echo "✓ config-api-tls was reissued after the Secret was deleted (revision $REV)"
exit 0
