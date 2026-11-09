#!/bin/bash

echo "Waiting for the Polyphone fleet, Flux, the git server and the first reconcile..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. The apps Kustomization is red after a release commit:"
echo ""
echo "  flux get kustomizations"
echo ""
