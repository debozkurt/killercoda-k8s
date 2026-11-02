#!/bin/bash
# Checks: the client's trust volume mounts the internal CA bundle, and the live mTLS call works.
BUNDLE=$(kubectl get deploy config-client -n app-services \
  -o jsonpath='{.spec.template.spec.volumes[?(@.name=="trust")].secret.secretName}' 2>/dev/null)
if [ "$BUNDLE" != "internal-ca-bundle" ]; then
  echo "config-client mounts '$BUNDLE' for trust. Point it at the internal CA bundle:" >&2
  echo "  kubectl patch deployment config-client -n app-services -p '{\"spec\":{\"template\":{\"spec\":{\"volumes\":[{\"name\":\"trust\",\"secret\":{\"secretName\":\"internal-ca-bundle\"}}]}}}}'" >&2
  exit 1
fi
AVAIL=$(kubectl get deployment config-client -n app-services -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${AVAIL:-0}" -lt 1 ]; then
  echo "config-client mounts internal-ca-bundle, but the new Pod is still rolling. Wait, then run:" >&2
  echo "  kubectl rollout status deployment/config-client -n app-services" >&2
  exit 1
fi
OUT=$(kubectl exec -n app-services deploy/config-client -- curl -sS -m 10 --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/ 2>&1)
if ! echo "$OUT" | grep -q "mTLS OK"; then
  echo "The client mounts the right bundle, but the call still fails: $OUT" >&2
  exit 1
fi
echo "✓ config-client trusts the internal CA, and the mTLS call succeeds"
exit 0
