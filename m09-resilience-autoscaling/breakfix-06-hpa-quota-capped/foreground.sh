#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "caption-engine (captions) has an autoscaler that wants 4 replicas, but the"
echo "service runs on 2. The autoscaler reads healthy. Start here:"
echo ""
echo "  kubectl get hpa -n captions"
echo "  kubectl get deploy -n captions"
