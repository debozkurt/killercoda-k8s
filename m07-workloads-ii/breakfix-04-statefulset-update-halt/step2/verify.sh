#!/bin/bash
# Checks: session-store is back at 3 Ready replicas and the template no longer names the
# nonexistent tag. Asserts the outcome (template fixed AND the broken Pod replaced), not the
# exact command used.
IMG=$(kubectl get statefulset session-store -n app-services -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "$IMG" = "nginx:1.25.99" ]; then
  echo "The template still names nginx:1.25.99, which does not exist. Revert it: kubectl rollout undo statefulset/session-store -n app-services" >&2
  exit 1
fi
READY=$(kubectl get statefulset session-store -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
READY=${READY:-0}
if [ "$READY" -lt 3 ]; then
  echo "The template is fixed but only $READY/3 are Ready. OrderedReady does not replace an un-Ready Pod on its own. Delete the Pod that still runs the bad image: kubectl delete pod session-store-2 -n app-services" >&2
  exit 1
fi
echo "✓ session-store is 3/3 Ready on a template that names a real image; the broken ordinal was replaced"
exit 0
