#!/bin/bash
# Checks: session-broker's Pod was actually scheduled (has a nodeName), so the
# Scheduled-event story in this step holds. Defensive baseline check.
NODE=$(kubectl get pod -n media -l app=session-broker -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
if [ -z "$NODE" ]; then
  echo "session-broker has no assigned node yet — it hasn't been scheduled. The cluster may still be coming up; wait and retry." >&2
  exit 1
fi
echo "✓ session-broker was scheduled onto node: $NODE"
exit 0
