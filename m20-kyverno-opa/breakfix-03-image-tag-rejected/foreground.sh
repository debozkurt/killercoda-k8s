#!/bin/bash

echo "Waiting for the Polyphone baseline + Kyverno to spin up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "call-recorder in tenant-apps is 0/1 with no Pods. Read the ReplicaSet's denial —"
echo "and note which policy names it (image rule, not the limits rule):"
echo ""
echo "  kubectl get deploy,rs,pods -n tenant-apps -l app=call-recorder"
echo "  kubectl describe rs -n tenant-apps -l app=call-recorder | sed -n '/Events/,\$p'"
echo ""
