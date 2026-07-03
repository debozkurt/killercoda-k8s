#!/bin/bash

echo "Waiting for the Polyphone baseline + the admission webhook to spin up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "orders-api in tenant-apps is 0/1 with no Pods — rejected for a missing 'env' label the"
echo "author never sets. Read the denial, then ask why the mutating webhook didn't inject it:"
echo ""
echo "  kubectl describe rs -n tenant-apps -l app=orders-api | sed -n '/Events/,\$p'"
echo "  kubectl get mutatingwebhookconfiguration admission-guard -o yaml | sed -n '/rules:/,/sideEffects/p'"
echo ""
