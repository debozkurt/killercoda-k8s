#!/bin/bash
# Checks the rendering trace: prod-us-east-1 and prod-eu-central-1 render, the
# region-owned vars (REGION, MAX_SESSIONS) differ per region, and the leaf-owned
# tier is identical — proving each cluster var has one owning layer.
FLEET=/root/fleet

USE=$(kubectl kustomize "$FLEET/clusters/prod-us-east-1" 2>/dev/null)
EUC=$(kubectl kustomize "$FLEET/clusters/prod-eu-central-1" 2>/dev/null)
[ -n "$USE" ] || { echo "prod-us-east-1 did not render." >&2; exit 1; }
[ -n "$EUC" ] || { echo "prod-eu-central-1 did not render." >&2; exit 1; }

echo "$USE" | grep -q 'REGION: us-east-1'     || { echo "prod-us-east-1 should render REGION: us-east-1." >&2; exit 1; }
echo "$EUC" | grep -q 'REGION: eu-central-1'  || { echo "prod-eu-central-1 should render REGION: eu-central-1." >&2; exit 1; }
echo "$USE" | grep -q 'MAX_SESSIONS: "8000"'  || { echo "prod-us-east-1 should inherit the us-east-1 capacity 8000." >&2; exit 1; }
echo "$EUC" | grep -q 'MAX_SESSIONS: "4000"'  || { echo "prod-eu-central-1 should inherit the eu-central-1 capacity 4000." >&2; exit 1; }
echo "$USE" | grep -q 'tier: prod'            || { echo "prod-us-east-1 should carry tier: prod (leaf-owned)." >&2; exit 1; }
echo "$EUC" | grep -q 'tier: prod'            || { echo "prod-eu-central-1 should carry tier: prod (leaf-owned)." >&2; exit 1; }

echo "✓ Trace holds: region-owned vars differ per region (8000/us-east-1 vs 4000/eu-central-1); leaf-owned tier is shared (prod)."
exit 0
