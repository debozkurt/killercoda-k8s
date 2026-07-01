#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "route-watcher (call-routing) is CrashLoopBackOff with a 403 — same as last time?"
echo "Read the logs, and this time read WHICH identity the Forbidden names:"
echo ""
echo "  kubectl get pods -n call-routing -l app=route-watcher"
echo "  kubectl logs -n call-routing deploy/route-watcher --tail=8"
echo ""
