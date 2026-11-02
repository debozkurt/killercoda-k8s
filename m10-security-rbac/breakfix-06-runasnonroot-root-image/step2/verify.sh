#!/bin/bash
# Checks: payments still enforces restricted, ledger-sync keeps runAsNonRoot=true, and the
# Deployment is Available, so the container now runs as a non-root user.
LEVEL=$(kubectl get ns payments -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$LEVEL" != "restricted" ]; then
  echo "Namespace payments no longer enforces restricted (found '${LEVEL:-no label}'). Restore it:" >&2
  echo "  kubectl label ns payments pod-security.kubernetes.io/enforce=restricted --overwrite" >&2
  exit 1
fi
NONROOT=$(kubectl get deploy ledger-sync -n payments -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}{.spec.template.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null)
case "$NONROOT" in
  *true*) ;;
  *)
    echo "ledger-sync no longer sets runAsNonRoot: true. Keep the check and set a non-root user instead:" >&2
    echo "  kubectl patch deployment ledger-sync -n payments -p '{\"spec\":{\"template\":{\"spec\":{\"securityContext\":{\"runAsNonRoot\":true,\"runAsUser\":1000}}}}}'" >&2
    exit 1 ;;
esac
for i in 1 2 3 4 5 6; do
  AVAIL=$(kubectl get deploy ledger-sync -n payments -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [ "$AVAIL" = "1" ] && break
  sleep 5
done
if [ "$AVAIL" != "1" ]; then
  echo "ledger-sync has no available replica. Read the kubelet's reason:" >&2
  echo "  kubectl describe pod -n payments -l app=ledger-sync" >&2
  exit 1
fi
kubectl get deploy,pods -n payments
echo "✓ ledger-sync is Available with runAsNonRoot kept and a non-root user"
exit 0
