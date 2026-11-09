#!/bin/bash
# Checks: the Deployment references a hashed ConfigMap again, all 3 replicas are
# ready, and every edge-relay container holds MAX_SESSIONS=6000.
NS=edge
REF=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
case "$REF" in
  edge-relay-config-*) : ;;
  *) echo "The Deployment references '$REF', a name with no hash, so the next config change will not roll." >&2
     echo "Remove generatorOptions.disableNameSuffixHash from overlays/prod, then:" >&2
     echo "  kubectl apply -k /root/edge-relay/overlays/prod --prune -l app=edge-relay" >&2
     exit 1 ;;
esac
READY=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${READY:-0}" -lt 3 ]; then
  echo "edge-relay has ${READY:-0}/3 ready replicas. Wait for the rollout:" >&2
  echo "  kubectl rollout status deployment/edge-relay -n edge" >&2
  exit 1
fi
# Skip Pods that are terminating; they still report Running during their grace period.
for P in $(kubectl get pods -n "$NS" -l app=edge-relay -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.deletionTimestamp}{"\n"}{end}' | grep '|$' | cut -d'|' -f1); do
  V=$(kubectl exec -n "$NS" "$P" -- printenv MAX_SESSIONS 2>/dev/null)
  if [ "$V" != "6000" ]; then
    echo "Pod $P holds MAX_SESSIONS='$V', not 6000. Wait for the rollout to finish and retry." >&2
    exit 1
  fi
done
echo "✓ edge-relay references $REF, runs 3/3, and every container holds MAX_SESSIONS=6000"
exit 0
