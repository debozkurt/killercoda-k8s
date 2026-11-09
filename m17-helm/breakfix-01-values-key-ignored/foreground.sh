#!/bin/bash

echo "Waiting for the Polyphone fleet and the voicemail release..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. The load test asked for 3 voicemail replicas. Start with:"
echo ""
echo "  helm get values voicemail -n app-services"
echo "  kubectl get deployment voicemail -n app-services"
echo ""
