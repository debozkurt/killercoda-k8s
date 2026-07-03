#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "sip-monitor (signaling) is stuck at 1/2 — one of its two containers is down."
echo "Find which, and why:"
echo ""
echo "  kubectl get pods -n signaling -l app=sip-monitor"
echo "  kubectl describe pod -n signaling -l app=sip-monitor | sed -n '/Events:/,\$p'"
echo ""
