#!/bin/bash

echo "Waiting for the Polyphone baseline + the secrets pipeline to come up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Two consumers are down in two namespaces. Begin with:"
echo ""
echo "  kubectl get secretsync -A"
echo "  kubectl get pods -n provisioning -l app=billing-processor"
echo ""
