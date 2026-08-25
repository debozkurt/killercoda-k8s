#!/bin/bash
# Checks: the session-broker Pod is back and holds an IP, so the delete in this
# step healed before the next one runs. Defensive baseline check.
IP=$(kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
if [ -z "$IP" ]; then
  echo "No session-broker Pod IP yet. The Deployment is replacing the Pod — wait and retry." >&2
  exit 1
fi
echo "✓ session-broker reachable at $IP"
exit 0
