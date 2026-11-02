#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Pods in the media namespace cannot resolve names. CoreDNS looks healthy."
echo "Reproduce the failure (it takes several seconds to fail):"
echo ""
echo "  kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \\"
echo "    wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local./"
echo ""
