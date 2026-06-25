#!/bin/bash

echo "Spinning up the Polyphone fleet (a config change isn't taking effect)..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. session-broker's log level was raised but didn't take. Begin:"
echo ""
echo "  kubectl get configmap app-config -n media -o jsonpath='{.data.LOG_LEVEL}'; echo"
echo "  kubectl exec deploy/session-broker -n media -- printenv LOG_LEVEL"
echo ""
