#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(session-cache is wedged by design — one workload never reaches full readiness)"
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "session-cache should have 3 replicas, but only session-cache-0 exists and it"
echo "isn't Ready. Start by looking at the set and its Pods:"
echo ""
echo "  kubectl get statefulset session-cache -n media"
echo "  kubectl get pods -n media -l app=session-cache"
echo ""
