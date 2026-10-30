#!/bin/bash
# Checks: the operator re-created the deleted child orion-media (self-heal) and the deleted
# tenant lyra is gone together with its child lyra-media (finalizer released, cascade ran).
if kubectl get mediatenant lyra -n media >/dev/null 2>&1; then
  echo "MediaTenant lyra still exists. Run: kubectl delete mediatenant lyra -n media (it can take ~10 seconds while the operator removes its finalizer)." >&2
  exit 1
fi
if kubectl get deployment lyra-media -n media >/dev/null 2>&1; then
  echo "lyra is gone but lyra-media is still listed. The garbage collector needs a few seconds. Wait and retry." >&2
  exit 1
fi
if ! kubectl get deployment orion-media -n media >/dev/null 2>&1; then
  echo "orion-media does not exist. Run step 5 delete command, then wait ~15 seconds for the operator to re-create it." >&2
  exit 1
fi
echo "✓ lyra and lyra-media are gone (finalizer released, cascade ran); orion-media exists (the operator re-created it)"
exit 0
