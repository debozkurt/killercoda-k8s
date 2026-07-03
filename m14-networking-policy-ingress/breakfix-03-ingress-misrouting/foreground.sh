#!/bin/bash

echo "Waiting for the Polyphone baseline + ingress controller to spin up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "portal.polyphone.example returns 503 — but portal-ui itself is healthy."
echo "Reproduce the 503 through the controller, then read the rule vs the Service:"
echo ""
echo "  CIP=\$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.clusterIP}')"
echo "  kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \\"
echo "    wget -O- --timeout=5 --header \"Host: portal.polyphone.example\" http://\$CIP/"
echo ""
