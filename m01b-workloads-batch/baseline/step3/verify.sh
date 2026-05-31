#!/bin/bash
# Checks: usage-export is sized for 4 shards and all 4 succeeded.
COMPLETIONS=$(kubectl get job usage-export -n analytics -o jsonpath='{.spec.completions}' 2>/dev/null)
[ "$COMPLETIONS" = "4" ] || { echo "usage-export completions=$COMPLETIONS, expected 4 (one per daily shard)" >&2; exit 1; }

SUCCEEDED=$(kubectl get job usage-export -n analytics -o jsonpath='{.status.succeeded}' 2>/dev/null)
[ "$SUCCEEDED" = "4" ] || { echo "usage-export succeeded=$SUCCEEDED/4 — the Job may still be running; re-check in a few seconds" >&2; exit 1; }

echo "✓ Parallel Job healthy: usage-export 4/4 shards complete (parallelism caps concurrency, completions sizes the work)"
exit 0
