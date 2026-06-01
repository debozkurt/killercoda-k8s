#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. account-provisioner won't start. Start here:"
echo ""
echo "  kubectl get pods -n provisioning"
echo "  kubectl describe pod -n provisioning -l app=account-provisioner | sed -n '/Events/,\$p'"
echo ""
echo "ImagePullBackOff is a category, not a diagnosis. Read the event message."
echo ""
