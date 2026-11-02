#!/bin/bash
# Checks: the CA issuer is Ready, both leaf Certificates are Ready, both Deployments are
# available, and the live mTLS call works.
READY=$(kubectl get clusterissuer polyphone-ca -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$READY" != "True" ]; then
  echo "ClusterIssuer polyphone-ca is not Ready (status=$READY). Give it the real signing Secret:" >&2
  echo "  kubectl patch clusterissuer polyphone-ca --type=merge -p '{\"spec\":{\"ca\":{\"secretName\":\"polyphone-internal-ca\"}}}'" >&2
  exit 1
fi
for pair in "config-api-tls:media" "config-client-tls:app-services"; do
  c="${pair%%:*}"; ns="${pair##*:}"
  R=$(kubectl get certificate "$c" -n "$ns" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  if [ "$R" != "True" ]; then
    echo "The issuer is Ready, but $c is not yet (status=$R). cert-manager retries on its own. Wait 10 seconds, then run:" >&2
    echo "  kubectl get certificate -A" >&2
    exit 1
  fi
done
for pair in "config-api:media" "config-client:app-services"; do
  d="${pair%%:*}"; ns="${pair##*:}"
  A=$(kubectl get deployment "$d" -n "$ns" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  if [ "${A:-0}" -lt 1 ]; then
    echo "Both certs are Ready, but $d has no available Pod. Roll it to skip the mount retry delay:" >&2
    echo "  kubectl rollout restart deployment/$d -n $ns" >&2
    exit 1
  fi
done
OUT=$(kubectl exec -n app-services deploy/config-client -- curl -sS -m 10 --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key --cacert /etc/tls/trust/ca.crt https://config-api.media.svc.cluster.local/ 2>&1)
if ! echo "$OUT" | grep -q "mTLS OK"; then
  echo "Both Pods run, but the call fails: $OUT" >&2
  exit 1
fi
echo "✓ polyphone-ca is Ready, both leaf certs issued, and the mTLS call succeeds"
exit 0
