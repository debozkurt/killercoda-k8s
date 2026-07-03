#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "sip-app (app-services) can't reach session-broker (media) — it times out,"
echo "even though an allow policy naming sip-app exists. Reproduce it as sip-app:"
echo ""
echo "  kubectl run sip-app --rm -i --restart=Never --labels app=sip-app \\"
echo "    --image=busybox:1.36 -n app-services -- \\"
echo "    wget -qO- --timeout=5 http://session-broker.media/"
echo ""
