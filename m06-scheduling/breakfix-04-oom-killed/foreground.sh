#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "media-buffer (media) scheduled onto a node — but it's in CrashLoopBackOff."
echo "It's not a scheduling problem this time. Read what killed the container:"
echo ""
echo "  kubectl get pods -n media -l app=media-buffer"
echo "  kubectl describe pod -n media -l app=media-buffer | grep -A5 'Last State'"
echo ""
