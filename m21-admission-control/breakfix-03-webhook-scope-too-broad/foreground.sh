#!/bin/bash

echo "Waiting for the Polyphone baseline + the admission webhook to spin up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "sip-canary in the signaling namespace is 0/1 with no Pods — rejected by admission-guard,"
echo "the tenant webhook that has no business touching signaling. Read the denial, then its scope:"
echo ""
echo "  kubectl describe rs -n signaling -l app=sip-canary | sed -n '/Events/,\$p'"
echo "  kubectl get validatingwebhookconfiguration admission-guard -o jsonpath='{.webhooks[0].namespaceSelector}{\"\\n\"}'"
echo ""
