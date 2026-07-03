#!/bin/bash
# Checks: the server Certificate's dnsNames now include the FQDN clients dial, so its
# reissued SANs cover the connection target. Deterministic field check on the root cause.
FQDN="config-api.media.svc.cluster.local"
DNSNAMES=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.spec.dnsNames[*]}' 2>/dev/null)
if [ -z "$DNSNAMES" ]; then
  echo "Couldn't read config-api-tls' dnsNames — is the Certificate present in namespace media?" >&2
  exit 1
fi
case " $DNSNAMES " in
  *" $FQDN "*) : ;;
  *)
    echo "config-api-tls' dnsNames still don't include $FQDN (current: $DNSNAMES). Add the real Service names: kubectl patch certificate config-api-tls -n media --type=merge -p '{\"spec\":{\"dnsNames\":[\"config-api.media.svc.cluster.local\",\"config-api.media.svc\",\"config-api\"]}}'" >&2
    exit 1 ;;
esac
READY=$(kubectl get certificate config-api-tls -n media -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$READY" != "True" ]; then
  echo "dnsNames include $FQDN but the cert isn't Ready yet (status=$READY) — cert-manager is reissuing. Wait and retry." >&2
  exit 1
fi
echo "✓ config-api-tls now lists $FQDN in its SANs and is Ready — hostname verification will pass (roll config-api so nginx serves the reissued cert)"
exit 0
