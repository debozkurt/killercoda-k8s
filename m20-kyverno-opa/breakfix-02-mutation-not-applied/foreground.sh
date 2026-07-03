#!/bin/bash

echo "Waiting for the Polyphone baseline + Kyverno to spin up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "tenant-portal is Running but missing its owner label. The workload is healthy —"
echo "the missing default is the whole symptom. Confirm it, then read the mutate policy:"
echo ""
echo "  kubectl get pods -n tenant-apps -L owner"
echo "  kubectl get clusterpolicy add-owner-label -o yaml | grep -A12 'rules:'"
echo ""
