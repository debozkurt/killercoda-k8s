#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10"
echo " namespaces and the 17-workload fleet, several backed by PVCs)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by looking at the claims the fleet holds:"
echo ""
echo "  kubectl get pvc -A"
echo "  kubectl get pv"
echo "  kubectl get storageclass"
echo ""
