#!/bin/bash
# Checks: the Service still resolves and has a backend, so all three paths in
# this step are exercisable. Defensive baseline check.
SVC_IP=$(kubectl get svc session-broker -n media -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
POD_IP=$(kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
if [ -z "$SVC_IP" ] || [ -z "$POD_IP" ]; then
  echo "session-broker is missing its ClusterIP or its Pod IP — wait for the Pod to be Ready and retry." >&2
  exit 1
fi
echo "✓ both paths addressable — pod: $POD_IP, service: $SVC_IP"
exit 0
