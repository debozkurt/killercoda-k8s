#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "A kernel patch is waiting on the worker, and the drain is stuck on trunk-monitor"
echo "(signaling). Its budget asks for 1 of 2 replicas, which looks reasonable, but the"
echo "eviction is refused. Start here:"
echo ""
echo "  kubectl get pdb -n signaling"
echo "  kubectl describe pdb trunk-monitor -n signaling"
