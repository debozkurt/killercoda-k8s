#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "rtp-probe (edge) should run on every node, but reports only 1. Compare its"
echo "coverage to sbc-edge, which reaches both nodes:"
echo ""
echo "  kubectl get daemonset -n edge"
echo "  kubectl get pods -n edge -o wide"
echo ""
