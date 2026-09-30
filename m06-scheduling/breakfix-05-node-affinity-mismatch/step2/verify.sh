#!/bin/bash
# Checks: conference-mixer has an available replica, and the worker still carries
# disktype=ssd (the fix corrected the Pod's selector, not the node's label).
# Asserts the outcome, not the exact command used.
AVAIL=$(kubectl get deploy conference-mixer -n media -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAIL" != "1" ]; then
  echo "conference-mixer has no available replica, so it is not scheduled. Point its selector at a label a node carries:" >&2
  echo "  kubectl patch deployment conference-mixer -n media -p '{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"disktype\":\"ssd\"}}}}}'" >&2
  exit 1
fi
if kubectl get nodes -l disktype=nvme --no-headers 2>/dev/null | grep -q .; then
  echo "A node now carries disktype=nvme. That label claims hardware the node does not have. Remove it and fix the Pod instead:" >&2
  echo "  kubectl label nodes -l disktype=nvme disktype=ssd --overwrite" >&2
  exit 1
fi
echo "✓ conference-mixer is Available (1/1); its selector matches a label the worker really carries"
exit 0
