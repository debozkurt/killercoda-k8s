#!/bin/bash

echo "Waiting for the Polyphone baseline and the ingress-nginx controller..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "The portal home page loads through the Ingress, but a deep link returns 404."
echo "Start by reading what the Ingress rule says:"
echo ""
echo "  kubectl get ingress -n admin-portal"
echo ""
