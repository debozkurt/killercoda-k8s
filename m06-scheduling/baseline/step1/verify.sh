#!/bin/bash
# Checks: the cluster has both nodes Ready (control-plane + worker), so the
# placement story in this step holds. Defensive baseline check.
READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready")
if [ "$READY" -lt 2 ]; then
  echo "Expected 2 Ready nodes, found $READY. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ Both nodes are Ready (control-plane + worker)"
exit 0
