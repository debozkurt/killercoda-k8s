#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s and the ingress-nginx"
echo " controller; provisions 10 namespaces and the 17-workload fleet; then applies a"
echo " NetworkPolicy set in 'media', an Ingress for portal-ui, and the probe-demo Pod)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start with the policies in 'media':"
echo ""
echo "  kubectl get networkpolicy -n media"
echo "  kubectl get ingress -A"
echo ""
echo "(Each test call comes from a throwaway client that you create with kubectl run --rm.)"
echo ""
