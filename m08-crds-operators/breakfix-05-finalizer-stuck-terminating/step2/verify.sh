#!/bin/bash
# Checks: vega is gone, the operator is running again, and the operator's own log shows it ran the
# cleanup (so a hand-edited finalizer does not pass). vega-media must be collected as well.
if kubectl get mediatenant vega -n media >/dev/null 2>&1; then
  echo "MediaTenant vega still exists (Terminating). Restore its controller: kubectl scale deployment tenant-operator -n platform --replicas=1" >&2
  exit 1
fi
READY=$(kubectl get deployment tenant-operator -n platform -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${READY:-0}" -lt 1 ]; then
  echo "vega is gone, but the tenant-operator is not running. Scale it back to 1 replica and wait for it to be Ready." >&2
  exit 1
fi
if ! kubectl logs deployment/tenant-operator -n platform 2>/dev/null | grep -q "media/vega: cleanup done"; then
  echo "vega is gone, but the operator never ran its cleanup (no 'cleanup done' line). The finalizer was probably removed by hand. Do not skip the controller's cleanup on a real tenant." >&2
  exit 1
fi
if kubectl get deployment vega-media -n media >/dev/null 2>&1; then
  echo "vega is gone, but vega-media is still listed. The garbage collector needs a few seconds. Wait and retry." >&2
  exit 1
fi
echo "✓ The operator ran its cleanup and released vega, and the garbage collector removed vega-media"
exit 0
