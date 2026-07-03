#!/bin/bash

echo "Waiting for the Polyphone baseline..."
echo "(the voicemail install is expected to have failed — that's the scenario)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. The voicemail release did not install. Confirm, then find out why:"
echo ""
echo "  helm list -n app-services"
echo "  helm install voicemail /root/voicemail --namespace app-services --set replicaCount=2"
echo ""
