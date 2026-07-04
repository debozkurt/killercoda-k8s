#!/bin/bash
# Checks: the flux CLI is installed and the GitRepository source has a good
# artifact (Ready=True). Read-only tour step — nothing to fix.
command -v flux >/dev/null 2>&1 || { echo "flux CLI not found on PATH" >&2; exit 1; }

READY=$(kubectl get gitrepository polyphone-config -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "GitRepository polyphone-config is not Ready (got: ${READY:-none})" >&2; exit 1; }

echo "✓ Flux installed; GitRepository polyphone-config Ready with a stored artifact"
exit 0
