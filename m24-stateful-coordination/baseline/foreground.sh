#!/bin/bash

echo "Waiting for the Polyphone baseline + coordination workloads to spin up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions the"
echo " 17-workload fleet plus session-cache — a StatefulSet — and call-coordinator,"
echo " a leader-elected singleton)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start with the coordination workloads:"
echo ""
echo "  kubectl get statefulset -n media session-cache"
echo "  kubectl get pods -n media -l app=session-cache -o wide"
echo "  kubectl get lease -n call-routing"
echo ""
