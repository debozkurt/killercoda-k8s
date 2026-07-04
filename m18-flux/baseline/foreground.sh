#!/bin/bash

echo "Waiting for the Polyphone baseline + the Flux GitOps pipeline to come up..."
echo "(installs local-path-provisioner, metrics-server, k9s, the Flux controllers,"
echo " an in-cluster Gitea git server; seeds the config repo and runs the first reconcile)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Confirm Flux is healthy and see the sources:"
echo ""
echo "  flux check"
echo "  flux get sources git"
echo "  flux get all"
echo ""
