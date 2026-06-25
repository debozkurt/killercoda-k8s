#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10"
echo " namespaces and the 17-workload fleet; wires app-config, database-creds,"
echo " and portal-secrets into their consumers)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by listing the config objects on the fleet:"
echo ""
echo "  kubectl get configmaps -A | grep -v kube-"
echo "  kubectl get secrets -A | grep -v kube-"
echo "  kubectl get pods -n media -l app=session-broker"
echo ""
