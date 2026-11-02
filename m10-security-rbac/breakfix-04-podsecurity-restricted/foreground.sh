#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "payments-api (payments) reports 0/1 ready, and there are no Pods to look at,"
echo "not even Pending ones. Find out why nothing is created:"
echo ""
echo "  kubectl get deploy,rs,pods -n payments"
echo "  kubectl describe rs -n payments -l app=payments-api"
echo ""
