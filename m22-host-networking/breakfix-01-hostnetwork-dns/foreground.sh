#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "rtp-relay (media) is Running but can't resolve in-cluster Service names."
echo "It's a hostNetwork Pod — start by reading the resolver it actually got:"
echo ""
echo "  kubectl exec deploy/rtp-relay -n media -- cat /etc/resolv.conf"
echo "  kubectl exec deploy/rtp-relay -n media -- getent hosts session-broker.media.svc.cluster.local"
echo ""
