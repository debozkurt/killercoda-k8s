#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "payments-api (payments) reports 0/1 ready — but there are no Pods to look at,"
echo "not even Pending ones. Find out why nothing is being created:"
echo ""
echo "  kubectl get deploy,rs,pods -n payments"
echo "  kubectl get events -n payments | grep -i -E 'failed|forbidden'"
echo ""
