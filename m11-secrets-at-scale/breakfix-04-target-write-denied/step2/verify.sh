#!/bin/bash
# Checks: the operator SA can write secrets in provisioning but not cluster-wide,
# db-credentials is Synced, and billing-processor is Ready.
SA=system:serviceaccount:secrets-system:secret-operator
if [ "$(kubectl auth can-i create secrets -n provisioning --as=$SA 2>/dev/null)" != "yes" ]; then
  echo "secret-operator still cannot write secrets in provisioning. Bind its ClusterRole there:" >&2
  echo "  kubectl create rolebinding secret-operator-targets -n provisioning --clusterrole=secret-operator-secrets --serviceaccount=secrets-system:secret-operator" >&2
  exit 1
fi
if [ "$(kubectl auth can-i create secrets -n kube-system --as=$SA 2>/dev/null)" = "yes" ]; then
  echo "secret-operator can write secrets in kube-system. The fix granted too much. Remove the wide binding:" >&2
  echo "  kubectl get clusterrolebindings -o wide | grep secret-operator" >&2
  exit 1
fi
REASON=$(kubectl get secretsync db-credentials -n provisioning -o jsonpath='{.status.reason}' 2>/dev/null)
READY=$(kubectl get deployment billing-processor -n provisioning -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$REASON" != "Synced" ] || [ "$READY" != "1" ]; then
  echo "The grant works, but the pipeline has not recovered (sync: '$REASON', ready: '$READY'). Wait 30 seconds, then run:" >&2
  echo "  kubectl get secretsync -A" >&2
  exit 1
fi
kubectl get pods -n provisioning -l app=billing-processor
echo "✓ The operator writes in provisioning, db-credentials is Synced, and billing-processor is Ready"
exit 0
