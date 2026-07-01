#!/bin/bash
# Checks: no directory replica is left stuck Pending, and the Deployment's desired
# replicas are all Ready — i.e. the RWO volume is no longer asked to span nodes.
# Asserts the outcome (scale to 1, or a genuine RWX move), not a specific command.
PENDING=$(kubectl get pods -n app-services -l app=directory \
  --field-selector=status.phase=Pending -o name 2>/dev/null | grep -c .)
if [ "$PENDING" -gt 0 ]; then
  echo "$PENDING directory replica(s) still Pending — an RWO volume can't back Pods on two nodes. Scale to a single consumer: kubectl scale deployment directory -n app-services --replicas=1" >&2
  exit 1
fi
DESIRED=$(kubectl get deploy directory -n app-services -o jsonpath='{.spec.replicas}' 2>/dev/null)
READY=$(kubectl get deploy directory -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
READY=${READY:-0}
if [ -z "$DESIRED" ] || [ "$READY" -lt 1 ] || [ "$READY" != "$DESIRED" ]; then
  echo "directory has $READY/$DESIRED replicas Ready. Give the rollout a few seconds, or scale to 1 so the single consumer runs on the volume's node." >&2
  exit 1
fi
echo "✓ directory is fully available ($READY/$DESIRED Ready), no replica stuck on the RWO volume"
exit 0
