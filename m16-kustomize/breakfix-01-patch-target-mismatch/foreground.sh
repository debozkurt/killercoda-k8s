#!/bin/bash

echo "Provisioning the fleet and attempting the edge-relay prod promotion..."
echo "(the prod apply is expected to fail at build time — that's the scenario)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. edge-relay should be running in 'edge' — but check:"
echo ""
echo "  kubectl get deploy -n edge"
echo ""
