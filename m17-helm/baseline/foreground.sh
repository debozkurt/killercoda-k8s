#!/bin/bash

echo "Waiting for the Polyphone baseline + the voicemail Helm release to come up..."
echo "(installs local-path-provisioner, metrics-server, k9s, the Helm CLI; provisions the fleet and the voicemail release)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Confirm Helm is installed and see the release:"
echo ""
echo "  helm version --short"
echo "  helm list -n app-services"
echo ""
