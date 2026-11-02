#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "release-auditor (provisioning) is CrashLoopBackOff with a 403, and its Role"
echo "lists the verb it needs. Read every field of the Forbidden:"
echo ""
echo "  kubectl get pods -n provisioning -l app=release-auditor"
echo "  kubectl logs -n provisioning deploy/release-auditor --tail=8"
echo ""
