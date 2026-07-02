#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "You've scheduled a kernel patch on the worker and need to drain it."
echo "sip-registrar (signaling) is Running 2/2, but its disruption budget is"
echo "blocking the drain. Start here:"
echo ""
echo "  kubectl get pdb -n signaling"
echo "  kubectl describe pdb sip-registrar -n signaling"
echo ""
