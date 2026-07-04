#!/bin/bash

echo "Waiting for the Polyphone baseline (+ Multus) to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "media-probe (edge) is stuck in ContainerCreating. Start with its status and the"
echo "event that says what Multus couldn't find:"
echo ""
echo "  kubectl get pods -n edge -l app=media-probe -o wide"
echo "  kubectl describe pod -n edge -l app=media-probe | tail -20"
echo ""
