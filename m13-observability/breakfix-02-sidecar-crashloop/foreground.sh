#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo "Waiting for the sidecar's first restart..."
until [ "$(kubectl get pod -n signaling -l app=sip-monitor \
  -o jsonpath='{.items[0].status.containerStatuses[?(@.name=="metrics-agent")].restartCount}' 2>/dev/null)" -ge 1 ] 2>/dev/null; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "sip-monitor in signaling reads 1/2 and its restart count climbs. Start with:"
echo ""
echo "  kubectl get pods -n signaling -l app=sip-monitor"
echo ""
