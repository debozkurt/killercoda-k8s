#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "transcode-scaler (media) has an autoscaler, but it isn't scaling and its"
echo "target reads <unknown>. metrics-server is installed and working. Read why:"
echo ""
echo "  kubectl get hpa -n media"
echo "  kubectl describe hpa transcode-scaler -n media"
echo ""
