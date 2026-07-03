#!/bin/bash

echo "Waiting for the Polyphone baseline + the voicemail release (two revisions)..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. A voicemail upgrade just 'succeeded' but the rollout is stuck."
echo "Look past helm status at the pods:"
echo ""
echo "  helm status voicemail -n app-services"
echo "  kubectl get pods -n app-services -l app=voicemail"
echo ""
