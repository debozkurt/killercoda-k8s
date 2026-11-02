#!/bin/bash

echo "Waiting for the Polyphone baseline + cert-manager to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "config-client cannot call config-api. Both Pods run. Start with the call itself:"
echo ""
echo "  kubectl exec -n app-services deploy/config-client -- curl -sS \\"
echo "    --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key --cacert /etc/tls/trust/ca.crt \\"
echo "    https://config-api.media.svc.cluster.local/"
echo ""
