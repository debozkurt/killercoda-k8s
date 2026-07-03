#!/bin/bash

echo "Waiting for the Polyphone baseline + cert-manager to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "config-api's cert is issued and correctly named, but config-client still can't"
echo "reach it. Reproduce the mTLS call and read the error:"
echo ""
echo "  kubectl exec -n app-services deploy/config-client -- \\"
echo "    curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \\"
echo "         --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/"
echo ""
