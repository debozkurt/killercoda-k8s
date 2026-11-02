#!/bin/bash

echo "Waiting for the Polyphone fleet and the secrets pipeline to come up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. A consumer in 'provisioning' won't start. Begin with:"
echo ""
echo "  kubectl get pods -n provisioning -l app=billing-processor"
echo "  kubectl get secretsync -A"
echo ""
