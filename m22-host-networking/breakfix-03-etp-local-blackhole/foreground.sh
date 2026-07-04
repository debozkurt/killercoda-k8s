#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "rtp-ingress (NodePort 30080) answers from one node's IP and hangs from the other."
echo "Reproduce the split by hitting the NodePort on every node's IP:"
echo ""
echo "  for ip in \$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type==\"InternalIP\")].address}'); do"
echo "    echo -n \"\$ip:30080 -> \"; curl -s --max-time 5 -o /dev/null -w '%{http_code}\\n' http://\$ip:30080 || echo TIMEOUT"
echo "  done"
echo ""
