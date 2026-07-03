#!/bin/bash

echo "Waiting for the Polyphone baseline + the secrets pipeline to come up..."
echo "(installs the fleet, then the backing store, the SecretSync CRD, the"
echo " secret-operator, and materializes two synced Secrets for their consumers)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by reading the pipeline's inputs:"
echo ""
echo "  kubectl get secretsync -A"
echo "  kubectl get secret vault-backend -n secrets-source -o yaml"
echo ""
