#!/bin/bash

echo "Waiting for the Polyphone baseline + the secrets pipeline to come up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. A consumer in 'media' won't start. Begin with:"
echo ""
echo "  kubectl get pods -n media -l app=partner-connector"
echo "  kubectl get secretsync -A"
echo ""
