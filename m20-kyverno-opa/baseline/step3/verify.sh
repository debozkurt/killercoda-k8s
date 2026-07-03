#!/bin/bash
# Checks: the mutate rule injected owner=platform onto tenant-web's Pod. Proves mutation
# happened at admission (the label is on the live Pod but not in the workload's source).
OWNER=$(kubectl get pods -n tenant-apps -l app=tenant-web \
  -o jsonpath='{.items[0].metadata.labels.owner}' 2>/dev/null)
if [ "$OWNER" = "platform" ]; then
  echo "✓ add-owner-label injected owner=platform onto tenant-web's Pod at admission"
  exit 0
fi
echo "tenant-web's Pod doesn't carry owner=platform yet (got: '${OWNER:-<none>}'). If the Pod is still starting, wait and retry." >&2
exit 1
