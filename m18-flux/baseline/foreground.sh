#!/bin/bash

echo "Waiting for the Polyphone fleet, Flux, the git server and the first reconcile..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start with the controllers and the source:"
echo ""
echo "  flux check"
echo "  flux get sources git"
echo ""
