#!/bin/bash

echo "Waiting for the Polyphone fleet and the edge-relay Kustomize tree (about 1 to 2 minutes)..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Alert: edge-relay in prod still rejects sessions above 5000 (MAX_SESSIONS was raised to 6000). Start with:"
echo ""
echo "  kubectl exec -n edge deploy/edge-relay -- printenv MAX_SESSIONS"
echo ""
