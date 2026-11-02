#!/bin/bash
# Checks: payments still enforces restricted (the fix must not relax the namespace), and
# payments-api is Available, which under enforce=restricted proves a compliant Pod template.
LEVEL=$(kubectl get ns payments -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$LEVEL" != "restricted" ]; then
  echo "Namespace payments no longer enforces restricted (found '${LEVEL:-no label}'). Restore it and fix the workload instead:" >&2
  echo "  kubectl label ns payments pod-security.kubernetes.io/enforce=restricted --overwrite" >&2
  exit 1
fi
for i in 1 2 3 4 5 6; do
  AVAIL=$(kubectl get deploy payments-api -n payments -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [ "$AVAIL" = "1" ] && break
  sleep 5
done
if [ "$AVAIL" != "1" ]; then
  echo "payments-api has no available replica. Read the refusal, then add the fields it lists:" >&2
  echo "  kubectl describe rs -n payments -l app=payments-api" >&2
  exit 1
fi
kubectl get deploy,pods -n payments
echo "✓ payments-api is Available under enforce=restricted"
exit 0
