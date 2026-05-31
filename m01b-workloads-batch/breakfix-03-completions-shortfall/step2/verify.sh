#!/bin/bash
# Checks: usage-export is now sized for 4 shards and all 4 succeeded.
COMPLETIONS=$(kubectl get job usage-export -n analytics -o jsonpath='{.spec.completions}' 2>/dev/null)
if [ "$COMPLETIONS" != "4" ]; then
  echo "usage-export completions=$COMPLETIONS, expected 4. completions is immutable — delete and recreate with completions: 4 (see step 2)." >&2
  exit 1
fi

SUCCEEDED=$(kubectl get job usage-export -n analytics -o jsonpath='{.status.succeeded}' 2>/dev/null)
[ "$SUCCEEDED" = "4" ] || { echo "usage-export succeeded=$SUCCEEDED/4 — if you just recreated it, give it a few seconds: kubectl wait --for=condition=complete job/usage-export -n analytics --timeout=60s" >&2; exit 1; }

echo "✓ Completions fixed: usage-export 4/4 shards exported — Complete now matches correct"
exit 0
