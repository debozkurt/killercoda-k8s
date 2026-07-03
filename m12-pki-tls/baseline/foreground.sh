#!/bin/bash

echo "Waiting for the Polyphone baseline + cert-manager to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s, cert-manager; provisions"
echo " 10 namespaces + the 17-workload fleet, an internal CA, and an mTLS pair)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start with cert-manager and the internal CA:"
echo ""
echo "  kubectl get pods -n cert-manager"
echo "  kubectl get clusterissuers"
echo "  kubectl get certificate -A"
echo ""
