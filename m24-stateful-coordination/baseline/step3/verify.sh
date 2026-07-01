#!/bin/bash
# Checks: session-cache uses OrderedReady and is back to 3/3 Ready after the scale
# demo, so its ordered lifecycle is intact. Defensive baseline check.
POLICY=$(kubectl get statefulset session-cache -n media -o jsonpath='{.spec.podManagementPolicy}' 2>/dev/null)
if [ "$POLICY" != "OrderedReady" ]; then
  echo "session-cache podManagementPolicy is '$POLICY', expected OrderedReady." >&2
  exit 1
fi
READY=$(kubectl get statefulset session-cache -n media -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY" != "3" ]; then
  echo "session-cache is at $READY/3 Ready. If you scaled down, scale back to 3 (kubectl scale statefulset session-cache -n media --replicas=3) and wait." >&2
  exit 1
fi
echo "✓ session-cache is OrderedReady and back to 3/3 Ready"
exit 0
