#!/bin/bash

echo "Spinning up the Polyphone fleet (a workload has a wrong credential)..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. account-provisioner is up but can't authenticate. Begin:"
echo ""
echo "  kubectl get pods -n provisioning"
echo "  kubectl exec deploy/account-provisioner -n provisioning -- printenv DB_PASSWORD"
echo ""
