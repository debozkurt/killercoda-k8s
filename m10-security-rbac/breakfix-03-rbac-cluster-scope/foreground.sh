#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "node-inspector (analytics) is CrashLoopBackOff with a 403. Read the logs, and"
echo "notice how the Forbidden message ENDS — the last words are the diagnosis:"
echo ""
echo "  kubectl get pods -n analytics -l app=node-inspector"
echo "  kubectl logs -n analytics deploy/node-inspector --tail=8"
echo ""
