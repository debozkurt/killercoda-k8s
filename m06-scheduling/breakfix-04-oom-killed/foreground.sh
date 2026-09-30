#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "media-buffer (media) has a node, and it is in CrashLoopBackOff."
echo "This is not a scheduling problem. Read what killed the container:"
echo ""
echo "  kubectl get pods -n media -l app=media-buffer"
echo "  kubectl describe pod -n media -l app=media-buffer"
echo ""
