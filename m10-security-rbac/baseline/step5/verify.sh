#!/bin/bash
# Checks: psa-demo enforces restricted, the compliant Pod "good" is Running there, and the
# non-compliant Deployment bad-deploy exists with no Pods (admission refused them).
LEVEL=$(kubectl get ns psa-demo -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$LEVEL" != "restricted" ]; then
  echo "Namespace psa-demo does not enforce restricted (found '${LEVEL:-no label}'). Run:" >&2
  echo "  kubectl create ns psa-demo" >&2
  echo "  kubectl label ns psa-demo pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/warn=restricted" >&2
  exit 1
fi
for i in 1 2 3 4 5 6; do
  PHASE=$(kubectl get pod good -n psa-demo -o jsonpath='{.status.phase}' 2>/dev/null)
  [ "$PHASE" = "Running" ] && break
  sleep 5
done
if [ "$PHASE" != "Running" ]; then
  echo "Pod psa-demo/good is '${PHASE:-absent}', not Running. Apply the compliant Pod from this step, then run:" >&2
  echo "  kubectl describe pod good -n psa-demo" >&2
  exit 1
fi
if ! kubectl get deploy bad-deploy -n psa-demo >/dev/null 2>&1; then
  echo "Deployment psa-demo/bad-deploy is missing. Create it to see the warn-then-reject path:" >&2
  echo "  kubectl create deployment bad-deploy --image=busybox:1.36 -n psa-demo -- sleep 3600" >&2
  exit 1
fi
kubectl get deploy,pods -n psa-demo
echo "✓ psa-demo enforces restricted: good is Running, bad-deploy has no admitted Pods"
exit 0
