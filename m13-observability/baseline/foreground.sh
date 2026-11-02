#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10"
echo " namespaces + the 17-workload fleet, plus call-metrics and restart-demo)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by reading the event stream:"
echo ""
echo "  kubectl events -A | tail -20"
echo "  kubectl top nodes"
echo ""
