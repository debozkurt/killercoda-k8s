#!/bin/bash

echo "Waiting for the Polyphone fleet and the edge-relay Kustomize tree (about 1 to 2 minutes)..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Alert: edge-relay capacity in prod is one third of plan (planned: 3 replicas). Start with:"
echo ""
echo "  kubectl get deploy edge-relay -n edge"
echo ""
