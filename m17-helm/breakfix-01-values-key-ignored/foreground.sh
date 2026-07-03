#!/bin/bash

echo "Waiting for the Polyphone baseline + the voicemail release..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. The voicemail release was installed to run 3 replicas."
echo "Check what's actually running:"
echo ""
echo "  helm get values voicemail -n app-services"
echo "  kubectl get deployment voicemail -n app-services"
echo ""
