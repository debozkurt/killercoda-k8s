#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10"
echo " namespaces and the 17-workload fleet, each fronted by its Services)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by looking at the Services the fleet runs:"
echo ""
echo "  kubectl get svc -A"
echo "  kubectl get endpointslice -n media \
  -l kubernetes.io/service-name=session-broker"
echo ""
echo "(Traffic is driven from a throwaway client you create with kubectl run --rm;"
echo " the fleet's own nginx Pods don't make outbound calls.)"
echo ""
