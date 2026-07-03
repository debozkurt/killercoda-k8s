#!/bin/bash
# Checks: the leaf Certificate is Ready and produced a kubernetes.io/tls Secret.
# Defensive baseline check — nothing is broken.
READY=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$READY" != "True" ]; then
  echo "config-api-tls isn't Ready yet (status=$READY). cert-manager may still be issuing — wait and retry." >&2
  exit 1
fi
TYPE=$(kubectl get secret config-api-tls -n media -o jsonpath='{.type}' 2>/dev/null)
if [ "$TYPE" != "kubernetes.io/tls" ]; then
  echo "The Secret config-api-tls is missing or not a kubernetes.io/tls Secret (type=$TYPE). Wait for issuance and retry." >&2
  exit 1
fi
echo "✓ config-api-tls is Ready and produced a kubernetes.io/tls Secret (tls.crt / tls.key / ca.crt)"
exit 0
