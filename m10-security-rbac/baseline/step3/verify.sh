#!/bin/bash
# Checks: the learner bound the built-in view ClusterRole to media/config-reader with a
# RoleBinding, so the account can list configmaps in media but not in signaling.
ROLE=$(kubectl get rolebinding config-reader-view -n media -o jsonpath='{.roleRef.kind}/{.roleRef.name}' 2>/dev/null)
if [ "$ROLE" != "ClusterRole/view" ]; then
  echo "RoleBinding media/config-reader-view does not reference ClusterRole view (found '${ROLE:-nothing}'). Run:" >&2
  echo "  kubectl create serviceaccount config-reader -n media" >&2
  echo "  kubectl create rolebinding config-reader-view -n media --clusterrole=view --serviceaccount=media:config-reader" >&2
  exit 1
fi
IN=$(kubectl auth can-i list configmaps -n media --as=system:serviceaccount:media:config-reader 2>/dev/null)
OUT=$(kubectl auth can-i list configmaps -n signaling --as=system:serviceaccount:media:config-reader 2>/dev/null)
if [ "$IN" != "yes" ]; then
  echo "config-reader still cannot list configmaps in media (auth can-i = '$IN'). Check the binding's subject:" >&2
  echo "  kubectl describe rolebinding config-reader-view -n media" >&2
  exit 1
fi
if [ "$OUT" = "yes" ]; then
  echo "config-reader can list configmaps in signaling too. A cluster-wide grant exists; this step wants a RoleBinding in media only." >&2
  exit 1
fi
echo "✓ config-reader can list configmaps in media (yes) and not in signaling (no)"
exit 0
