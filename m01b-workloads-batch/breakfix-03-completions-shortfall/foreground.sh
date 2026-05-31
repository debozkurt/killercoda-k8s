#!/bin/bash

echo "Waiting for the Polyphone baseline + scenario mutation..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. Finance filed a ticket:"
echo ""
echo "  +-----------------------------------------------+"
echo "  | TICKET: daily usage export missing data       |"
echo "  | job:      usage-export (analytics)            |"
echo "  | symptom:  only 1 of 4 shards downstream       |"
echo "  | status:   Job reports COMPLETE (!)            |"
echo "  +-----------------------------------------------+"
echo ""
echo "Green status, wrong result. Start with:"
echo ""
echo "  kubectl get job usage-export -n analytics"
echo ""
