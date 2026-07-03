#!/bin/bash

echo "Waiting for the Polyphone baseline + cert-manager to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "config-api (media) is stuck and won't serve HTTPS. Start with the Pod, then"
echo "the Certificate behind the Secret it mounts:"
echo ""
echo "  kubectl get pods -n media -l app=config-api"
echo "  kubectl get certificate config-api-tls -n media"
echo ""
