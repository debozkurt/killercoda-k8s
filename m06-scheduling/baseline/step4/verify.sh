#!/bin/bash
# Checks: the learner released the placement-demo reservation, and session-broker
# holds a node (the Scheduled event this step reads exists). Defensive baseline check.
if kubectl get pod placement-demo -n analytics >/dev/null 2>&1; then
  echo "placement-demo still exists, so its requests still hold room on the worker. Run:" >&2
  echo "  kubectl delete pod placement-demo -n analytics" >&2
  exit 1
fi
NODE=$(kubectl get pod -n media -l app=session-broker -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
if [ -z "$NODE" ]; then
  echo "session-broker has no node yet. The fleet may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ placement-demo is deleted and its reservation released; session-broker runs on $NODE"
exit 0
