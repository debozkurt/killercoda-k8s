#!/bin/bash

echo "Waiting for the Polyphone baseline + cert-manager to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Two workloads in two namespaces are stuck. Start with the Pods and the Certificates:"
echo ""
echo "  kubectl get pods -n media -l app=config-api"
echo "  kubectl get pods -n app-services -l app=config-client"
echo "  kubectl get certificate -A"
echo ""
