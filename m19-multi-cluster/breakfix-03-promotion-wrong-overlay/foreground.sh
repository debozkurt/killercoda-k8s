#!/bin/bash

echo "Provisioning the fleet and applying the stage-us-east-1 cluster..."
echo "(1.27 was promoted to stage this morning — but stage still runs 1.25)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. stage-us-east-1 is running in 'edge'. Check the image each us-east-1 tier renders:"
echo ""
echo "  cd /root/fleet && for t in lab stage prod; do echo -n \"\$t: \"; kubectl kustomize clusters/\$t-us-east-1 | grep -m1 'image: nginx'; done"
echo ""
