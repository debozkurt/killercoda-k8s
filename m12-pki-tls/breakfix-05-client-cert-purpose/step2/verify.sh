#!/bin/bash
# Checks: the client Certificate asks for client auth, the issued cert carries it, and the
# live mTLS call works.
USAGES=$(kubectl get certificate config-client-tls -n app-services -o jsonpath='{.spec.usages[*]}' 2>/dev/null)
case " $USAGES " in
  *" client auth "*) : ;;
  *)
    echo "The usages of config-client-tls do not include client auth (current: $USAGES). Restore them:" >&2
    echo "  kubectl patch certificate config-client-tls -n app-services --type=merge -p '{\"spec\":{\"usages\":[\"client auth\",\"digital signature\",\"key encipherment\"]}}'" >&2
    exit 1 ;;
esac
EKU=$(kubectl get secret config-client-tls -n app-services -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -ext extendedKeyUsage 2>/dev/null)
if ! echo "$EKU" | grep -q "Client Authentication"; then
  echo "The spec is right, but the issued cert is not Client Authentication yet. cert-manager is reissuing. Wait 10 seconds, then run:" >&2
  echo "  kubectl get secret config-client-tls -n app-services -o jsonpath='{.data.tls\\.crt}' | base64 -d | openssl x509 -noout -ext extendedKeyUsage" >&2
  exit 1
fi
OUT=$(kubectl exec -n app-services deploy/config-client -- curl -sS -m 10 --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/ 2>&1)
if ! echo "$OUT" | grep -q "mTLS OK"; then
  echo "The cert is right, but the client still presents the old one from its mounted Secret. Roll the client:" >&2
  echo "  kubectl rollout restart deployment/config-client -n app-services" >&2
  exit 1
fi
echo "✓ config-client's cert carries Client Authentication, and the mTLS call succeeds"
exit 0
