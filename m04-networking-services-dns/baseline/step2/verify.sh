#!/bin/bash
# Checks: session-broker's EndpointSlice is populated (the selector matches Ready
# Pods), so the Service has backends. Defensive baseline check.
EP=$(kubectl get endpoints session-broker -n media -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
if [ -z "$EP" ]; then
  echo "session-broker has no endpoints yet. The Pods may still be becoming Ready — wait and retry." >&2
  exit 1
fi
echo "✓ session-broker has a populated EndpointSlice (first backend: $EP)"
exit 0
