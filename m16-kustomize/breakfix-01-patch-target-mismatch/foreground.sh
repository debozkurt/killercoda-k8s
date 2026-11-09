#!/bin/bash

echo "Waiting for the Polyphone fleet and the edge-relay Kustomize tree (about 1 to 2 minutes)..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Alert: the edge-relay prod deploy job failed. It runs, from /root/edge-relay:"
echo ""
echo "  kubectl apply -k overlays/prod"
echo ""
