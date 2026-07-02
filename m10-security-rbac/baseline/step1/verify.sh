#!/bin/bash
# Checks: the default ServiceAccount exists in the media namespace, so the
# identity story in this step holds. Defensive baseline check.
if ! kubectl get serviceaccount default -n media >/dev/null 2>&1; then
  echo "The 'default' ServiceAccount isn't present in namespace media yet. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ media/default ServiceAccount exists — the identity every fleet Pod there runs as"
exit 0
