#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10 namespaces and the fleet,"
echo " with sip-app configured as the gold-standard workload)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by looking at the owner chain:"
echo ""
echo "  kubectl get deploy,rs,pods -n app-services -l app=sip-app"
echo ""
