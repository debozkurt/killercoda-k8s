#!/bin/bash
# Checks: the node-inspector SA can now `list nodes` at the cluster scope — which
# only a ClusterRole + ClusterRoleBinding can grant. Deterministic and immediate,
# independent of the Pod's CrashLoop backoff timer. No -n: the question is cluster-scoped.
CAN=$(kubectl auth can-i list nodes \
  --as=system:serviceaccount:analytics:node-inspector 2>/dev/null)
if [ "$CAN" != "yes" ]; then
  echo "node-inspector still cannot 'list nodes' at the cluster scope (auth can-i = '$CAN'). Grant it with a ClusterRole + ClusterRoleBinding, e.g.: kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes && kubectl create clusterrolebinding node-inspector --clusterrole=node-reader --serviceaccount=analytics:node-inspector" >&2
  exit 1
fi
echo "✓ node-inspector can now list nodes at the cluster scope — granted via a ClusterRoleBinding"
exit 0
