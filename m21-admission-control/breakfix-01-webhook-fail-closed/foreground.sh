#!/bin/bash

echo "Waiting for the Polyphone baseline + the admission webhook to spin up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "billing-api in tenant-apps is 0/1 with no Pods. Start where the reason lives — the"
echo "ReplicaSet's events, not the (nonexistent) Pod — and read the webhook error closely:"
echo ""
echo "  kubectl get deploy,rs,pods -n tenant-apps -l app=billing-api"
echo "  kubectl describe rs -n tenant-apps -l app=billing-api | sed -n '/Events/,\$p'"
echo "  kubectl get pods,endpoints -n admission"
echo ""
