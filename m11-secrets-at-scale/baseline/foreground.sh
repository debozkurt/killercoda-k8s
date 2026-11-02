#!/bin/bash

echo "Waiting for the Polyphone fleet and the secrets pipeline to come up..."
echo "(fleet, then the backing store, the SecretSync CRD, the secret-operator,"
echo " two synced Secrets, and their consumers)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start with the pipeline's inputs:"
echo ""
echo "  kubectl get secretsync -A"
echo ""
