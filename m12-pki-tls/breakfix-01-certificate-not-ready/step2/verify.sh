#!/bin/bash
# Checks: the Certificate references a real issuer, is Ready, wrote its Secret,
# and config-api serves (the Pod mounted the Secret).
ISSUER=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.spec.issuerRef.name}' 2>/dev/null)
if [ -z "$ISSUER" ]; then
  echo "Could not read the issuerRef of config-api-tls. Check that the Certificate exists in namespace media:" >&2
  echo "  kubectl get certificate -n media" >&2
  exit 1
fi
if ! kubectl get clusterissuer "$ISSUER" >/dev/null 2>&1; then
  echo "config-api-tls still names an issuer that does not exist (issuerRef.name='$ISSUER'). Point it at the real one:" >&2
  echo "  kubectl patch certificate config-api-tls -n media --type=merge -p '{\"spec\":{\"issuerRef\":{\"name\":\"polyphone-ca\"}}}'" >&2
  exit 1
fi
READY=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$READY" != "True" ] || ! kubectl get secret config-api-tls -n media >/dev/null 2>&1; then
  echo "config-api-tls names '$ISSUER' but is not Ready yet (status=$READY). Wait for cert-manager to reissue, then run:" >&2
  echo "  kubectl get certificate config-api-tls -n media" >&2
  exit 1
fi
AVAIL=$(kubectl get deployment config-api -n media -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${AVAIL:-0}" -lt 1 ]; then
  echo "The Secret exists, but config-api has no available Pod. Roll the Deployment to skip the mount retry delay:" >&2
  echo "  kubectl rollout restart deployment/config-api -n media" >&2
  exit 1
fi
kubectl get pods -n media -l app=config-api
echo "✓ config-api-tls uses a real issuer ($ISSUER), is Ready, and config-api is serving"
exit 0
