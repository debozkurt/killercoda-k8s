#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "cdr-writer (cdr-storage) is stuck Pending and never starts."
echo "Don't chase the Pod — check the claim it's waiting on:"
echo ""
echo "  kubectl get pvc -n cdr-storage"
echo ""
