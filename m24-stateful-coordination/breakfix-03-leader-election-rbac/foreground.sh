#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "call-coordinator's Pods are Running, but no leader is ever elected."
echo "Start by looking for the Lease that should record the holder:"
echo ""
echo "  kubectl get pods -n call-routing -l app=call-coordinator"
echo "  kubectl get lease call-coordinator -n call-routing"
echo ""
