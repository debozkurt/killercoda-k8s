#!/bin/bash

echo "Waiting for the Polyphone fleet and the edge-relay Kustomize tree (about 1 to 2 minutes)..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Alert: edge-relay in prod is at 0 of 3 available replicas. Start with:"
echo ""
echo "  kubectl get pods -n edge -l app=edge-relay"
echo ""
