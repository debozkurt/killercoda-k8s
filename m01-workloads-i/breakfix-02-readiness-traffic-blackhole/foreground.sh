#!/bin/bash

echo "Waiting for the Polyphone baseline + scenario mutation..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. Alert fires:"
echo ""
echo "  +-----------------------------------------------+"
echo "  | ALERT: directory unreachable                  |"
echo "  | namespace: app-services                       |"
echo "  | impact:    address-book lookups failing       |"
echo "  +-----------------------------------------------+"
echo ""
echo "The pods are Running. So why is no traffic getting through? Start with:"
echo ""
echo "  kubectl get pods -n app-services -l app=directory"
echo ""
