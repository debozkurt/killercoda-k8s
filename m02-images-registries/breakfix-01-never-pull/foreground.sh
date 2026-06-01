#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. A deploy to analytics left metrics-aggregator stuck."
echo "Start here:"
echo ""
echo "  kubectl get pods -n analytics"
echo ""
echo "Note the STATUS column — it is NOT the ImagePullBackOff you saw in M00."
echo ""
