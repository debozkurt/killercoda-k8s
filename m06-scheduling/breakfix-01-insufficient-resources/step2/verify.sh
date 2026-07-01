#!/bin/bash
# Checks: stream-analyzer's memory request now fits a node and the Deployment has an
# available replica (the Pod scheduled and is Running). Asserts the outcome, not the command.
AVAIL=$(kubectl get deploy stream-analyzer -n analytics -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAIL" != "1" ]; then
  REQ=$(kubectl get deploy stream-analyzer -n analytics -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null)
  echo "stream-analyzer still has no available replica (memory request='$REQ'). Right-size it, e.g.: kubectl set resources deployment/stream-analyzer -n analytics --requests=memory=256Mi --limits=memory=512Mi" >&2
  exit 1
fi
echo "✓ stream-analyzer is Available (1/1) — its request now fits a node"
exit 0
