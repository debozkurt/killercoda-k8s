#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "endpoint-watcher (media) is CrashLoopBackOff. Its container keeps exiting —"
echo "read why, in its own logs:"
echo ""
echo "  kubectl get pods -n media -l app=endpoint-watcher"
echo "  kubectl logs -n media deploy/endpoint-watcher --tail=8"
echo ""
