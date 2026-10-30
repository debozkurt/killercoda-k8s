#!/bin/bash

echo "Waiting for the Polyphone baseline and the MediaTenant operator to come up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "kubectl delete mediatenant vega never finished: vega is still listed."
echo "Find what blocks the deletion:"
echo ""
echo "  kubectl describe mediatenant vega -n media"
echo ""
