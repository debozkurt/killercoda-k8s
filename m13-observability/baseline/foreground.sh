#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10"
echo " namespaces + the 17-workload fleet, plus a call-metrics scrape target)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by reading the three signals — events first:"
echo ""
echo "  kubectl get events -A --sort-by=.lastTimestamp | tail -20"
echo "  kubectl top nodes"
echo ""
