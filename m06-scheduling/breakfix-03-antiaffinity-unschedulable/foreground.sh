#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "sip-director (signaling) wants 3 replicas but only 1 is Running."
echo "Two Pods are Pending — and nothing is short on resources. Read why:"
echo ""
echo "  kubectl get pods -n signaling -l app=sip-director -o wide"
echo "  kubectl describe pod -n signaling -l app=sip-director | grep -A6 Events"
echo ""
