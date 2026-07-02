#!/bin/bash
# Checks: route-engine is fully available after the rollout exercises in this step.
# Defensive baseline check — asserts the toured Deployment is healthy, not a specific
# learner action (rollout restart / undo both leave it Available).
AVAIL=$(kubectl get deploy route-engine -n call-routing -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
DESIRED=$(kubectl get deploy route-engine -n call-routing -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ -z "$AVAIL" ] || [ "$AVAIL" != "$DESIRED" ]; then
  echo "route-engine is not fully available yet (${AVAIL:-0}/${DESIRED:-?}). A rollout may still be in progress — wait for 'kubectl rollout status' to finish and retry." >&2
  exit 1
fi
echo "✓ route-engine is fully available ($AVAIL/$DESIRED) — rollout settled"
exit 0
