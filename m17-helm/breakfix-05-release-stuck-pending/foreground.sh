#!/bin/bash

echo "Waiting for the Polyphone fleet and the voicemail release..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Ship the new voicemail greeting:"
echo ""
echo "  helm upgrade voicemail /root/voicemail --namespace app-services --reuse-values \\"
echo "    --set config.greeting=\"Please leave a message after the tone.\""
echo ""
