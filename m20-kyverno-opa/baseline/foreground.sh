#!/bin/bash

echo "Waiting for the Polyphone baseline + Kyverno to spin up..."
echo "(installs local-path-provisioner, metrics-server, k9s, and the Kyverno policy"
echo " engine; provisions 10 namespaces + the 17-workload fleet; then applies three"
echo " ClusterPolicies scoped to 'tenant-apps' and a compliant 'tenant-web' workload)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start with the policy engine and the policies it enforces:"
echo ""
echo "  kubectl get pods -n kyverno"
echo "  kubectl get clusterpolicy"
echo "  kubectl get deploy -n tenant-apps"
echo ""
