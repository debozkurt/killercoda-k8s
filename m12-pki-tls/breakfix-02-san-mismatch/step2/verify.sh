#!/bin/bash
# Checks: the issued cert's SANs cover the name clients dial, and the live mTLS call works.
FQDN="config-api.media.svc.cluster.local"
DNSNAMES=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.spec.dnsNames[*]}' 2>/dev/null)
case " $DNSNAMES " in
  *" $FQDN "*) : ;;
  *)
    echo "The dnsNames of config-api-tls do not include $FQDN (current: $DNSNAMES). Restore the real Service names:" >&2
    echo "  kubectl patch certificate config-api-tls -n media --type=merge -p '{\"spec\":{\"dnsNames\":[\"config-api.media.svc.cluster.local\",\"config-api.media.svc\",\"config-api\"]}}'" >&2
    exit 1 ;;
esac
SANS=$(kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -ext subjectAltName 2>/dev/null)
if ! echo "$SANS" | grep -q "DNS:$FQDN"; then
  echo "The spec is right, but the issued cert does not list $FQDN yet. cert-manager is reissuing. Wait 10 seconds, then run:" >&2
  echo "  kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\\.crt}' | base64 -d | openssl x509 -noout -ext subjectAltName" >&2
  exit 1
fi
OUT=$(kubectl exec -n app-services deploy/config-client -- curl -sS -m 10 --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key --cacert /etc/tls/trust/ca.crt https://$FQDN/ 2>&1)
if ! echo "$OUT" | grep -q "mTLS OK"; then
  echo "The cert is right, but the call still fails. nginx serves the cert it loaded at startup. Roll the server:" >&2
  echo "  kubectl rollout restart deployment/config-api -n media" >&2
  exit 1
fi
echo "✓ config-api serves a cert that lists $FQDN, and the mTLS call succeeds"
exit 0
