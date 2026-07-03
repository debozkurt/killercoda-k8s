#!/bin/bash

echo "Waiting for the Polyphone baseline + edge-relay Kustomize tree to come up..."
echo "(provisions the 17-workload fleet, writes /root/edge-relay, applies the prod overlay)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Ready. The Kustomize tree is at /root/edge-relay. Start by rendering the base:"
echo ""
echo "  cd /root/edge-relay && kubectl kustomize base"
echo ""
