#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "stream-analyzer (analytics) has no running Pod. It is stuck Pending."
echo "The scheduler could not place it. Start here:"
echo ""
echo "  kubectl get pods -n analytics -o wide"
echo "  kubectl describe pod -n analytics -l app=stream-analyzer"
echo ""
