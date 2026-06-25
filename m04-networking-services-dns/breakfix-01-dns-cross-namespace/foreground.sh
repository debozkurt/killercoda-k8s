#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "account-provisioner (provisioning) can't reach the session broker."
echo "Start with the endpoint it's configured to call:"
echo ""
echo "  kubectl get deploy account-provisioner -n provisioning -o yaml | grep -A2 BROKER_ENDPOINT"
echo ""
