#!/bin/bash

echo "Waiting for the Polyphone baseline + edge-relay fleet repo to come up..."
echo "(provisions the 17-workload fleet, writes /root/fleet, applies the prod-us-east-1 cluster)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. The fleet repo is at /root/fleet. Start by reading the layout:"
echo ""
echo "  cd /root/fleet && find . -name kustomization.yaml | sort"
echo ""
