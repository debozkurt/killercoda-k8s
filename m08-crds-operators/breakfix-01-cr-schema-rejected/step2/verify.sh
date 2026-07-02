#!/bin/bash
# Checks: the vega MediaTenant now exists with a schema-valid tier, and the operator
# reconciled it into a child Deployment (vega-media). Asserts the outcome, not the
# exact command used.
TIER=$(kubectl get mediatenant vega -n media -o jsonpath='{.spec.tier}' 2>/dev/null)
if [ -z "$TIER" ]; then
  echo "MediaTenant vega still doesn't exist. Fix spec.tier to a valid enum value (gold, silver, or bronze) in /root/vega-tenant.yaml and re-apply: kubectl apply -f /root/vega-tenant.yaml" >&2
  exit 1
fi
case "$TIER" in
  gold|silver|bronze) : ;;
  *) echo "vega exists but spec.tier='$TIER' isn't one of gold/silver/bronze — it should have been rejected. Set a valid tier and re-apply." >&2; exit 1 ;;
esac
if ! kubectl get deployment vega-media -n media >/dev/null 2>&1; then
  echo "vega is valid (tier=$TIER) but the operator hasn't created vega-media yet. Give the reconcile loop a few seconds and retry." >&2
  exit 1
fi
echo "✓ vega accepted (tier=$TIER) and the operator provisioned vega-media — the schema was the gate, and the resource now conforms"
exit 0
