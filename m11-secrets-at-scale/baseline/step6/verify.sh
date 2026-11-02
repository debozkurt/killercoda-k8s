#!/bin/bash
# Checks: the pipeline is intact at the end of the tour (both syncs Synced and both
# consumers Ready), so the break/fix scenarios start from a known shape.
DB=$(kubectl get secretsync db-credentials -n provisioning -o jsonpath='{.status.reason}' 2>/dev/null)
PA=$(kubectl get secretsync partner-api -n media -o jsonpath='{.status.reason}' 2>/dev/null)
BR=$(kubectl get deployment billing-processor -n provisioning -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
PR=$(kubectl get deployment partner-connector -n media -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$DB" != "Synced" ] || [ "$PA" != "Synced" ] || [ "$BR" != "1" ] || [ "$PR" != "1" ]; then
  echo "The pipeline is not intact (db-credentials='$DB', partner-api='$PA', billing ready='$BR', partner ready='$PR'). Read the failing sync:" >&2
  echo "  kubectl get secretsync -A" >&2
  exit 1
fi
kubectl get secretsync -A
echo "✓ Both syncs Synced and both consumers Ready: the pipeline is intact"
exit 0
