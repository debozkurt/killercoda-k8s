#!/bin/bash

echo "Waiting for the Polyphone fleet, Flux, the git server and the first reconcile..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. dialplan and voicemail never arrived in app-services:"
echo ""
echo "  kubectl get deploy -n app-services"
echo ""
