#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "disk-exporter (media) rolled out, and no Pod of it exists. Compare its"
echo "numbers with a DaemonSet that works:"
echo ""
echo "  kubectl get daemonset -A"
echo ""
