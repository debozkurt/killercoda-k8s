#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "pstn-probe (edge) is stuck Pending — but no node is short on resources."
echo "Something is repelling it. Read the scheduler's reason, then the node:"
echo ""
echo "  kubectl describe pod -n edge -l app=pstn-probe | grep -A6 Events"
echo ""
