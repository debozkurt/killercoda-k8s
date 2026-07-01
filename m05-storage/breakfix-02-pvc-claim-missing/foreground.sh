#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "directory (app-services) is stuck Pending — but its claim looks fine."
echo "Read what the Pod is actually asking for, then list the claims:"
echo ""
echo "  kubectl describe pod -n app-services -l app=directory | grep -A6 Volumes"
echo "  kubectl get pvc -n app-services"
echo ""
