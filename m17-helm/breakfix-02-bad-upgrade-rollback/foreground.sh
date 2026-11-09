#!/bin/bash

echo "Waiting for the Polyphone fleet and the voicemail release (two revisions)..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. The voicemail upgrade reported success. Start with:"
echo ""
echo "  helm status voicemail -n app-services"
echo "  kubectl get pods -n app-services -l app=voicemail"
echo ""
