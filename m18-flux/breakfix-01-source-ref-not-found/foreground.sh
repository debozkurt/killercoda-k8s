#!/bin/bash

echo "Waiting for the Polyphone baseline + Flux (with a stalled source) to come up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. The GitOps workloads never deployed. Start at the source:"
echo ""
echo "  flux get sources git"
echo "  flux get kustomizations"
echo ""
