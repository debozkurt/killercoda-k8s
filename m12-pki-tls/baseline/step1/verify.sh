#!/bin/bash
# Checks: cert-manager is up and the internal CA chain exists and is Ready.
# Defensive baseline check — nothing is broken.
if ! kubectl get deployment cert-manager -n cert-manager >/dev/null 2>&1; then
  echo "cert-manager isn't installed yet. The cluster may still be coming up (cert-manager makes boot slower) — wait and retry." >&2
  exit 1
fi
if ! kubectl get clusterissuer polyphone-ca >/dev/null 2>&1; then
  echo "The internal CA issuer (polyphone-ca) isn't present yet. Wait for setup to finish and retry." >&2
  exit 1
fi
READY=$(kubectl get certificate polyphone-internal-ca -n cert-manager -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$READY" != "True" ]; then
  echo "The CA Certificate (polyphone-internal-ca) isn't Ready yet (status=$READY). Give cert-manager a moment and retry." >&2
  exit 1
fi
echo "✓ cert-manager is up, the internal CA (polyphone-internal-ca) is Ready, and the CA issuer (polyphone-ca) exists"
exit 0
