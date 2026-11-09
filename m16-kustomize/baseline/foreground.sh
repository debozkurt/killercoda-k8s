#!/bin/bash

echo "Waiting for the Polyphone fleet and the edge-relay Kustomize tree (about 1 to 2 minutes)..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. The Kustomize tree is at /root/edge-relay. Start by reading the base:"
echo ""
echo "  cd /root/edge-relay && cat base/kustomization.yaml"
echo ""
