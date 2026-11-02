#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "ledger-sync (payments) reports 0/1 ready. This time a Pod exists."
echo "Find out why its container never starts:"
echo ""
echo "  kubectl get deploy,pods -n payments"
echo "  kubectl describe pod -n payments -l app=ledger-sync"
echo ""
