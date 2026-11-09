#!/bin/bash
# Checks: the flux CLI is installed and the GitRepository has a stored artifact.
command -v flux >/dev/null 2>&1 || { echo "flux CLI not found on PATH. Setup did not finish; reload the scenario." >&2; exit 1; }

READY=$(kubectl get gitrepository polyphone-config -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || { echo "GitRepository polyphone-config is not Ready (got: ${READY:-none}). Run:" >&2; echo "  flux reconcile source git polyphone-config" >&2; exit 1; }

echo "✓ GitRepository polyphone-config is Ready with a stored artifact"
exit 0
