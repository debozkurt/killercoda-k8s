#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "session-cache's Pods are all Running, but peers can no longer resolve a"
echo "specific member by name. Start from the DNS name that should work:"
echo ""
echo "  kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \\"
echo "    nslookup session-cache-0.session-cache.media.svc.cluster.local"
echo ""
