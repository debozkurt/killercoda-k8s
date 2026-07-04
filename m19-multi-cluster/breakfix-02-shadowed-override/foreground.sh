#!/bin/bash

echo "Provisioning the fleet and applying the prod-us-east-1 cluster..."
echo "(the region standard is 8000 — but this cluster renders 5000)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. prod-us-east-1 is running in 'edge'. The region says 8000 — check what the cluster renders:"
echo ""
echo "  cd /root/fleet && kubectl kustomize clusters/prod-us-east-1 | grep MAX_SESSIONS"
echo ""
