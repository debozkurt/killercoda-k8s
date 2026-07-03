#!/bin/bash

echo "Waiting for the Polyphone baseline + the secrets pipeline to come up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. The pipeline is green, but billing-processor is failing auth."
echo "Start by confirming the pipeline really is healthy, then read what the process holds:"
echo ""
echo "  kubectl get secretsync -A"
echo "  kubectl exec deploy/billing-processor -n provisioning -- printenv DB_PASSWORD"
echo ""
