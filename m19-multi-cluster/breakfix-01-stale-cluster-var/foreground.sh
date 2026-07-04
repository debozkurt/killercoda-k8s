#!/bin/bash

echo "Provisioning the fleet and applying the prod-eu-central-1 cluster..."
echo "(the cluster comes up healthy — but reports the wrong region)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. prod-eu-central-1 is running in 'edge'. Check what region it thinks it's in:"
echo ""
echo "  cd /root/fleet && kubectl kustomize clusters/prod-eu-central-1 | grep REGION"
echo ""
