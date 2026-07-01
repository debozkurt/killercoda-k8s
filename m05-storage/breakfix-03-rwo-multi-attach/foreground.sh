#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "directory (app-services) has a replica stuck — but its PVC is Bound."
echo "See which Pod is stuck and where the replicas landed:"
echo ""
echo "  kubectl get pods -n app-services -l app=directory -o wide"
echo "  kubectl get pvc -n app-services"
echo ""
