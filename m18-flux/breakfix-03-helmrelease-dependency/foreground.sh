#!/bin/bash

echo "Waiting for the Polyphone baseline + Flux (voicemail release blocked) to come up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. The voicemail HelmRelease is stuck not-ready:"
echo ""
echo "  flux get helmreleases"
echo "  flux get kustomizations"
echo ""
