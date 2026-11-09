#!/bin/bash

echo "Waiting for the Polyphone fleet..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. The first Helm deploy of voicemail failed. Start with:"
echo ""
echo "  helm list -n app-services"
echo "  kubectl get deploy,svc -n app-services -l app=voicemail"
echo ""
