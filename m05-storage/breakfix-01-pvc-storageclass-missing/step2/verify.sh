#!/bin/bash
# Checks: cdr-data is now Bound via the real class (local-path), so cdr-writer can
# get its volume. Asserts the outcome, not a specific command.
SC=$(kubectl get pvc cdr-data -n cdr-storage -o jsonpath='{.spec.storageClassName}' 2>/dev/null)
STATUS=$(kubectl get pvc cdr-data -n cdr-storage -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$SC" = "fast-ssd" ] || [ -z "$SC" ]; then
  echo "cdr-data still references a bad/absent StorageClass (got '$SC'). storageClassName is immutable — delete and recreate the PVC with storageClassName: local-path (scale cdr-writer to 0 first)." >&2
  exit 1
fi
if [ "$STATUS" != "Bound" ]; then
  echo "cdr-data is '$STATUS', not Bound (class '$SC'). Make sure cdr-writer is scaled back up so a consumer triggers WaitForFirstConsumer binding." >&2
  exit 1
fi
echo "✓ cdr-data is Bound via StorageClass '$SC' — cdr-writer can get its volume"
exit 0
