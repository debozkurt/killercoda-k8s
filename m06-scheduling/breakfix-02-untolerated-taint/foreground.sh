#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "pstn-probe (edge) is stuck Pending, and no node is short of resources."
echo "Something repels it. Read the scheduler's reason:"
echo ""
echo "  kubectl describe pod -n edge -l app=pstn-probe"
echo ""
