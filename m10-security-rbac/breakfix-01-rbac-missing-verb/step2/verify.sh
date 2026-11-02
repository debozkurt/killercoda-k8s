#!/bin/bash
# Checks: the endpoint-watcher SA can list endpoints in media, and the reader Deployment
# is Available again (its Pod now gets HTTP 200 and stays up).
CAN=$(kubectl auth can-i list endpoints -n media \
  --as=system:serviceaccount:media:endpoint-watcher 2>/dev/null)
if [ "$CAN" != "yes" ]; then
  echo "endpoint-watcher still cannot list endpoints in media (auth can-i = '$CAN'). Add the list verb:" >&2
  echo "  kubectl patch role endpoint-reader -n media --type=json -p '[{\"op\":\"replace\",\"path\":\"/rules/0/verbs\",\"value\":[\"get\",\"list\",\"watch\"]}]'" >&2
  exit 1
fi
for i in 1 2 3 4 5 6; do
  AVAIL=$(kubectl get deploy endpoint-watcher -n media -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [ "$AVAIL" = "1" ] && break
  sleep 5
done
if [ "$AVAIL" != "1" ]; then
  echo "The RBAC is fixed, but endpoint-watcher is not Available yet. Clear the crash-loop backoff:" >&2
  echo "  kubectl rollout restart deployment endpoint-watcher -n media" >&2
  exit 1
fi
kubectl get pods -n media -l app=endpoint-watcher
echo "✓ endpoint-watcher can list endpoints in media and its Pod is Available"
exit 0
