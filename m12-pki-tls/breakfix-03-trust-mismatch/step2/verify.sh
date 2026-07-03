#!/bin/bash
# Checks: the client's trust volume now mounts the correct internal-CA bundle, so it
# can verify the server's cert. Deterministic field check on the root cause.
BUNDLE=$(kubectl get deploy config-client -n app-services \
  -o jsonpath='{.spec.template.spec.volumes[?(@.name=="trust")].secret.secretName}' 2>/dev/null)
if [ -z "$BUNDLE" ]; then
  echo "Couldn't read config-client's trust volume — is the Deployment present in app-services?" >&2
  exit 1
fi
if [ "$BUNDLE" != "internal-ca-bundle" ]; then
  echo "config-client still mounts the wrong trust bundle (secretName='$BUNDLE'). Point it at the internal CA: kubectl patch deployment config-client -n app-services -p '{\"spec\":{\"template\":{\"spec\":{\"volumes\":[{\"name\":\"trust\",\"secret\":{\"secretName\":\"internal-ca-bundle\"}}]}}}}'" >&2
  exit 1
fi
AVAIL=$(kubectl get deployment config-client -n app-services -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${AVAIL:-0}" -lt 1 ]; then
  echo "config-client mounts internal-ca-bundle but has no available replica yet — the new Pod is still rolling. Wait and retry." >&2
  exit 1
fi
echo "✓ config-client now trusts internal-ca-bundle (CN=polyphone-internal-ca) — it can verify the server's cert; mTLS succeeds"
exit 0
