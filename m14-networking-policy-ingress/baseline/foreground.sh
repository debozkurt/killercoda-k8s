#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s, and the ingress-nginx"
echo " controller; provisions 10 namespaces + the 17-workload fleet; then applies a"
echo " healthy NetworkPolicy set in 'media' and an Ingress fronting portal-ui)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start with the policies shaping traffic into 'media':"
echo ""
echo "  kubectl get networkpolicy -n media"
echo "  kubectl get ingress -A"
echo ""
echo "(Traffic is driven from throwaway clients you create with kubectl run --rm;"
echo " the fleet's own nginx Pods don't make outbound calls.)"
echo ""
