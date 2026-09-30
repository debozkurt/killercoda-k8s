#!/bin/bash
# Checks: media-buffer runs under a limit that fits its working set. The Deployment
# has an available replica, and no current Pod records an OOMKilled last state
# (a crash-looping Pod can look Available for a second between restarts).
# Asserts the outcome, not the command.
AVAIL=$(kubectl get deploy media-buffer -n media -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
REASONS=$(kubectl get pods -n media -l app=media-buffer -o jsonpath='{range .items[*]}{.status.containerStatuses[0].lastState.terminated.reason}{" "}{end}' 2>/dev/null)
if [ "$AVAIL" != "1" ] || echo "$REASONS" | grep -q OOMKilled; then
  LIM=$(kubectl get deploy media-buffer -n media -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
  echo "media-buffer is still being OOMKilled or is not available (memory limit '$LIM'). Raise the limit above its ~60Mi working set:" >&2
  echo "  kubectl set resources deployment/media-buffer -n media --limits=memory=128Mi" >&2
  echo "If you already did, wait for the old Pod to terminate and check again." >&2
  exit 1
fi
echo "✓ media-buffer is Available (1/1) with no OOMKilled restarts; its memory limit now covers the buffer"
exit 0
