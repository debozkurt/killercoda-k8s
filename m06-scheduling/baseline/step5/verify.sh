#!/bin/bash
# Checks: no Pod in the cluster is Pending, so the healthy baseline the break/fix
# scenarios start from is intact. Defensive baseline check.
PENDING=$(kubectl get pods -A --field-selector=status.phase=Pending --no-headers 2>/dev/null)
if [ -n "$PENDING" ]; then
  echo "Some Pods are still Pending:" >&2
  echo "$PENDING" >&2
  echo "Read the reason with: kubectl describe pod <name> -n <namespace>" >&2
  exit 1
fi
echo "✓ No Pod is Pending — every Pod in the cluster holds a node"
exit 0
