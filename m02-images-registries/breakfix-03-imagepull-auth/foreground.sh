#!/bin/bash

echo "Waiting for the Polyphone baseline + private registry to finish spinning up..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. media-recorder won't pull its image. Start here:"
echo ""
echo "  kubectl get pods -n media -l app=media-recorder"
echo "  kubectl describe pod -n media -l app=media-recorder | sed -n '/Events/,\$p'"
echo ""
echo "Same ImagePullBackOff as before — but read the event message for THIS cause."
echo ""
