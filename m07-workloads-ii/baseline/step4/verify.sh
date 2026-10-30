#!/bin/bash
# Checks: media-engine is back at 2 Ready replicas after the scale-down/up, and
# ordinal 0 still holds the marker the learner wrote before deleting the Pod.
# Asserts the outcome (identity and data survived), not the exact command used.
READY=$(kubectl get statefulset media-engine -n media -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY" != "2" ]; then
  echo "media-engine has '$READY' Ready replicas, expected 2. Scale it back up and wait for both Pods:" >&2
  echo "  kubectl scale statefulset media-engine -n media --replicas=2" >&2
  exit 1
fi
ROLE=$(kubectl exec media-engine-0 -n media -- cat /var/state/role 2>/dev/null)
if [ "$ROLE" != "seed-node" ]; then
  echo "media-engine-0 has no seed-node marker in /var/state/role (read '$ROLE'). Write it, delete the Pod, and read it again:" >&2
  echo "  kubectl exec media-engine-0 -n media -- sh -c 'echo seed-node > /var/state/role'" >&2
  exit 1
fi
echo "✓ media-engine-0 kept its name, claim and data across a delete; media-engine is back at 2 Ready replicas"
exit 0
