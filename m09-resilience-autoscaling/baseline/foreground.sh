#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10"
echo " namespaces and the 17-workload fleet, plus a healthy HPA and PDB)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by looking at how a Deployment updates itself:"
echo ""
echo "  kubectl rollout history deployment/route-engine -n call-routing"
echo "  kubectl get hpa -A"
echo "  kubectl get pdb -A"
echo ""
