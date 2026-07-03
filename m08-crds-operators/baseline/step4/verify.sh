#!/bin/bash
# Checks: the child Deployment orion-media carries an ownerReference back to the orion
# MediaTenant (matching uid) — the link cascading deletion follows. Defensive baseline check.
CR_UID=$(kubectl get mediatenant orion -n media -o jsonpath='{.metadata.uid}' 2>/dev/null)
OWNER_KIND=$(kubectl get deployment orion-media -n media \
  -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null)
OWNER_UID=$(kubectl get deployment orion-media -n media \
  -o jsonpath='{.metadata.ownerReferences[0].uid}' 2>/dev/null)
if [ "$OWNER_KIND" != "MediaTenant" ] || [ -z "$CR_UID" ] || [ "$OWNER_UID" != "$CR_UID" ]; then
  echo "orion-media's ownerReference doesn't point at the orion MediaTenant (kind='$OWNER_KIND', ref uid='$OWNER_UID', cr uid='$CR_UID'). The operator may still be reconciling — wait and retry." >&2
  exit 1
fi
echo "✓ orion-media is owned by the orion MediaTenant (ownerReference uid matches) — cascading deletion has a chain to follow"
exit 0
