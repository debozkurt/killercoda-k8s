#!/bin/bash

echo "Waiting for the Polyphone baseline + Kyverno to spin up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "billing-api in tenant-apps is 0/1 with no Pods at all. Start where the reason lives —"
echo "the ReplicaSet's events, not the (nonexistent) Pod:"
echo ""
echo "  kubectl get deploy,rs,pods -n tenant-apps"
echo "  kubectl get events -n tenant-apps --field-selector reason=FailedCreate"
echo ""
