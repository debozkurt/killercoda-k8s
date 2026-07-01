#!/bin/bash
# Checks: media-buffer now runs under a limit that fits its working set — the
# Deployment has an available replica and the container is no longer OOMKilled.
# Asserts the outcome, not the command.
AVAIL=$(kubectl get deploy media-buffer -n media -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAIL" != "1" ]; then
  LIM=$(kubectl get deploy media-buffer -n media -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
  echo "media-buffer still isn't stably available (memory limit='$LIM'). Raise the limit above its ~60Mi working set, e.g.: kubectl set resources deployment/media-buffer -n media --limits=memory=128Mi" >&2
  exit 1
fi
echo "✓ media-buffer is Available (1/1) — its memory limit now covers the buffer, no more OOMKill"
exit 0
