#!/bin/bash

echo "Provisioning the fleet and applying the edge-relay prod overlay..."
echo "(build and apply both succeed; the Pod then fails to start — that's the scenario)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. edge-relay applied, but the Pod isn't Running. Look:"
echo ""
echo "  kubectl get pods -n edge -l app=edge-relay"
echo ""
