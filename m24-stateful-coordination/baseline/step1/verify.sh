#!/bin/bash
# Checks: session-cache StatefulSet has all 3 replicas Ready and each ordinal has its
# own Bound PVC, so the learner has a healthy stable-identity workload to read.
READY=$(kubectl get statefulset session-cache -n media -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY" != "3" ]; then
  echo "session-cache is not fully Ready yet (readyReplicas='$READY'). The fleet may still be coming up — wait and retry." >&2
  exit 1
fi
for i in 0 1 2; do
  PHASE=$(kubectl get pvc "data-session-cache-$i" -n media -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ "$PHASE" != "Bound" ]; then
    echo "data-session-cache-$i is not Bound yet (phase '$PHASE'). Wait for the StatefulSet to finish and retry." >&2
    exit 1
  fi
done
echo "✓ session-cache is 3/3 Ready with per-Pod PVCs data-session-cache-{0,1,2} all Bound"
exit 0
