#!/bin/bash

echo "Waiting for the Polyphone baseline + the secrets pipeline to come up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. The pipeline reports green. Begin with:"
echo ""
echo "  kubectl get secretsync -A"
echo ""
