#!/bin/bash
# Checks: the Certificate now references a real issuer, is Ready, and produced its
# kubernetes.io/tls Secret — the root-cause fix for the stuck server.
ISSUER=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.spec.issuerRef.name}' 2>/dev/null)
if [ -z "$ISSUER" ]; then
  echo "Couldn't read config-api-tls' issuerRef — is the Certificate present in namespace media?" >&2
  exit 1
fi
if ! kubectl get clusterissuer "$ISSUER" >/dev/null 2>&1; then
  echo "config-api-tls still references an issuer that doesn't exist (issuerRef.name='$ISSUER'). Point it at the real internal-CA issuer: kubectl patch certificate config-api-tls -n media --type=merge -p '{\"spec\":{\"issuerRef\":{\"name\":\"polyphone-ca\"}}}'" >&2
  exit 1
fi
READY=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$READY" != "True" ]; then
  echo "config-api-tls references '$ISSUER' but isn't Ready yet (status=$READY). Give cert-manager a moment to reissue and retry." >&2
  exit 1
fi
if ! kubectl get secret config-api-tls -n media >/dev/null 2>&1; then
  echo "The Secret config-api-tls still doesn't exist. Wait for the Certificate to finish issuing and retry." >&2
  exit 1
fi
echo "✓ config-api-tls references a real issuer ($ISSUER), is Ready, and wrote its kubernetes.io/tls Secret — the server can mount it"
exit 0
