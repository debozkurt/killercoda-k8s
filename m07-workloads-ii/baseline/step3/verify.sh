#!/bin/bash
# Checks: media-engine's per-ordinal PVCs exist and are Bound, proving the
# volumeClaimTemplate stamped one claim per replica. Defensive baseline check.
BOUND=$(kubectl get pvc -n media --no-headers 2>/dev/null | grep -E 'state-media-engine-[0-9]' | grep -c Bound)
if [ "$BOUND" -lt 2 ]; then
  echo "Expected 2 Bound per-ordinal PVCs (state-media-engine-0/-1), found $BOUND Bound. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ Per-ordinal PVCs state-media-engine-0/-1 are Bound (one claim per replica)"
exit 0
