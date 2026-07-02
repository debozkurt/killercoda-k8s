#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10"
echo " namespaces and the 17-workload fleet across a 2-node cluster)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by listing the non-Deployment controllers:"
echo ""
echo "  kubectl get statefulset -A"
echo "  kubectl get daemonset -A"
echo ""
