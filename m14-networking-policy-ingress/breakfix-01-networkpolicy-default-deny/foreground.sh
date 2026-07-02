#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "session-broker (media) has gone dark — callers time out, but its Pods are"
echo "healthy. A hang (not refused, not NXDOMAIN) points at policy. Reproduce it:"
echo ""
echo "  kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \\"
echo "    wget -qO- --timeout=5 http://session-broker.media/"
echo ""
