#!/bin/bash

echo "Provisioning the fleet, deploying edge-relay to lab, then promoting to prod..."
echo "(the prod promotion is expected to be rejected by the API server — that's the scenario)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. edge-relay is on the lab spec; the prod promotion didn't take. Look:"
echo ""
echo "  kubectl get deploy edge-relay -n edge"
echo ""
