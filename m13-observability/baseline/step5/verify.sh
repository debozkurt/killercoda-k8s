#!/bin/bash
# Checks: the learner deleted restart-demo, so its logs are gone.
# Defensive baseline check: nothing is broken.
if kubectl get pod restart-demo -n analytics >/dev/null 2>&1; then
  echo "restart-demo still exists, so its logs still exist." >&2
  echo "  Delete it and read its logs again: kubectl delete pod restart-demo -n analytics; kubectl logs restart-demo -n analytics" >&2
  exit 1
fi
echo "✓ restart-demo is gone, and its logs went with it"
exit 0
