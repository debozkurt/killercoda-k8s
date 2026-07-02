#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "session-store (app-services) has 3 Running Pods, but its members can't"
echo "reach each other. Confirm the Pods are up, then try to resolve a peer:"
echo ""
echo "  kubectl get pods -n app-services -l app=session-store"
echo "  kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \\"
echo "    nslookup session-store-0.session-store.app-services.svc.cluster.local"
echo ""
