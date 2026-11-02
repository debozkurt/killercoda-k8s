#!/bin/bash

echo "Waiting for the Polyphone fleet and the secrets pipeline to come up..."
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
echo "  kubectl get pods -n media -l app=partner-connector"
echo ""
