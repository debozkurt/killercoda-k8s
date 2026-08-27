#!/bin/bash
# Checks: session-broker Service exists in `media` with an allocated ClusterIP,
# so the learner can reach it by name. Defensive baseline check.
CIP=$(kubectl get svc session-broker -n media -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CIP" ] || [ "$CIP" = "None" ]; then
  echo "session-broker has no ClusterIP (got '$CIP'). The fleet may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ session-broker Service has a stable ClusterIP: $CIP"
exit 0
