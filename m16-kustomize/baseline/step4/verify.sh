#!/bin/bash
# Checks the config-change -> new-hash -> rollout contract: after editing the
# prod generator to MAX_SESSIONS=6000 and re-applying, the Deployment references
# a ConfigMap that exists and carries 6000, and the workload is still healthy.
NS=edge

READY=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" -ge 3 ] || { echo "edge-relay should be 3/3 ready after the rollout, got ${READY:-0}." >&2; exit 1; }

REF=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
VAL=$(kubectl get configmap "$REF" -n "$NS" -o jsonpath='{.data.MAX_SESSIONS}' 2>/dev/null)
if [ "$VAL" != "6000" ]; then
  echo "Expected the referenced ConfigMap ($REF) to carry MAX_SESSIONS=6000 — did you edit overlays/prod and re-apply with 'kubectl apply -k'? Got '$VAL'." >&2
  exit 1
fi

echo "✓ Config change rolled cleanly: edge-relay 3/3, now referencing $REF (MAX_SESSIONS=6000)."
exit 0
