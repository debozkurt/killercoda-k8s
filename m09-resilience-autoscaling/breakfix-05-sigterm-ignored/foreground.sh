#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Old announce-player (media) Pods linger Terminating after every deploy, and last"
echo "night's node drain crawled. Nothing errors and every alert is green. Start here:"
echo ""
echo "  kubectl get pods -n media -l app=announce-player"
echo "  kubectl describe deployment announce-player -n media"
