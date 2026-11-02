#!/bin/bash
# Checks: node-inspector can list nodes at the cluster scope (only a ClusterRoleBinding
# grants that), and the reader Deployment is Available again.
CAN=$(kubectl auth can-i list nodes \
  --as=system:serviceaccount:analytics:node-inspector 2>/dev/null)
if [ "$CAN" != "yes" ]; then
  echo "node-inspector still cannot list nodes at the cluster scope (auth can-i = '$CAN'). Grant it cluster-wide:" >&2
  echo "  kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes" >&2
  echo "  kubectl create clusterrolebinding node-inspector --clusterrole=node-reader --serviceaccount=analytics:node-inspector" >&2
  exit 1
fi
for i in 1 2 3 4 5 6; do
  AVAIL=$(kubectl get deploy node-inspector -n analytics -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [ "$AVAIL" = "1" ] && break
  sleep 5
done
if [ "$AVAIL" != "1" ]; then
  echo "The grant works, but node-inspector is not Available yet. Clear the crash-loop backoff:" >&2
  echo "  kubectl rollout restart deployment node-inspector -n analytics" >&2
  exit 1
fi
kubectl get clusterrolebinding node-inspector -o wide
echo "✓ node-inspector can list nodes at the cluster scope and its Pod is Available"
exit 0
