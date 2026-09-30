#!/bin/bash
# Checks: stream-analyzer's resource requests now fit a node and the Deployment has
# an available replica (the Pod scheduled and is Running). Asserts the outcome, not the command.
AVAIL=$(kubectl get deploy stream-analyzer -n analytics -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAIL" != "1" ]; then
  CPU_REQ=$(kubectl get deploy stream-analyzer -n analytics -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
  MEM_REQ=$(kubectl get deploy stream-analyzer -n analytics -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null)
  echo "stream-analyzer still has no available replica (cpu request='$CPU_REQ', memory request='$MEM_REQ'). Restore the intended resources: kubectl set resources deployment/stream-analyzer -n analytics --requests=cpu=10m,memory=256Mi --limits=cpu=200m,memory=512Mi" >&2
  exit 1
fi
echo "✓ stream-analyzer is Available (1/1) — its requests now fit a node"
exit 0
