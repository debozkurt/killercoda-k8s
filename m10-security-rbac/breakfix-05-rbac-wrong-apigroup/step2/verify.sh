#!/bin/bash
# Checks: release-auditor can list deployments.apps in provisioning, and the auditor
# Deployment is Available again (its Pod gets HTTP 200 and stays up).
CAN=$(kubectl auth can-i list deployments.apps -n provisioning \
  --as=system:serviceaccount:provisioning:release-auditor 2>/dev/null)
if [ "$CAN" != "yes" ]; then
  echo "release-auditor still cannot list deployments.apps in provisioning (auth can-i = '$CAN'). Put the rule in the apps group:" >&2
  echo "  kubectl patch role release-reader -n provisioning --type=json -p '[{\"op\":\"replace\",\"path\":\"/rules/0/apiGroups\",\"value\":[\"apps\"]}]'" >&2
  exit 1
fi
for i in 1 2 3 4 5 6; do
  AVAIL=$(kubectl get deploy release-auditor -n provisioning -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [ "$AVAIL" = "1" ] && break
  sleep 5
done
if [ "$AVAIL" != "1" ]; then
  echo "The grant works, but release-auditor is not Available yet. Clear the crash-loop backoff:" >&2
  echo "  kubectl rollout restart deployment release-auditor -n provisioning" >&2
  exit 1
fi
kubectl get pods -n provisioning -l app=release-auditor
echo "✓ release-auditor can list deployments.apps and its Pod is Available"
exit 0
