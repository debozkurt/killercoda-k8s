#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. directory won't start. Start here:"
echo ""
echo "  kubectl get pods -n app-services -l app=directory"
echo "  kubectl describe pod -n app-services -l app=directory | sed -n '/Events/,\$p'"
echo ""
echo "Reachable? Authenticated? Then why won't it pull? Read the message."
echo ""
