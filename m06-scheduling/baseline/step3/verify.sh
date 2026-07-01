#!/bin/bash
# Checks: the worker node carries disktype=ssd, the label the fleet's media
# workloads require for scheduling. Defensive baseline check.
SSD=$(kubectl get nodes -l disktype=ssd --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$SSD" -lt 1 ]; then
  echo "No node carries disktype=ssd — media-engine/transcoder nodeAffinity would not match. The cluster may still be coming up; wait and retry." >&2
  exit 1
fi
echo "✓ A node is labeled disktype=ssd (the target of the fleet's nodeAffinity)"
exit 0
