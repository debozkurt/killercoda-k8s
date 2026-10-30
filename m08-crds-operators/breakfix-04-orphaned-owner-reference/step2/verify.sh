#!/bin/bash
# Checks: the orphan vega-media is gone, AND the legitimate child orion-media is still
# present and still owner-referenced to its MediaTenant (i.e. the learner removed only the
# orphan, not the healthy children).
if kubectl get deployment vega-media -n media >/dev/null 2>&1; then
  echo "vega-media still exists. It has no owner, so cascading deletion can't reclaim it — delete it directly: kubectl delete deployment vega-media -n media" >&2
  exit 1
fi
if ! kubectl get deployment orion-media -n media >/dev/null 2>&1; then
  echo "vega-media is gone, but so is orion-media — that's a legitimate, owned child and shouldn't have been deleted. Only the un-owned orphan needed removing." >&2
  exit 1
fi
OWNER=$(kubectl get deployment orion-media -n media \
  -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null)
if [ "$OWNER" != "MediaTenant" ]; then
  echo "orion-media exists but no longer has its MediaTenant ownerReference (got '$OWNER') — the healthy children should keep their owner links intact." >&2
  exit 1
fi
echo "✓ Orphan vega-media removed; orion-media remains and is still owned by its MediaTenant — cascading deletion stays intact for the live tenants"
exit 0
