#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "session-store (app-services) reads READY 2/3 after a release."
echo "Find which Pods run which revision, and why the rollout stopped:"
echo ""
echo "  kubectl get pods -n app-services -l app=session-store -L controller-revision-hash"
echo ""
