#!/bin/bash
# Checks the OUTCOME: the NodePort answers on EVERY node's IP. Satisfied by either fix
# (externalTrafficPolicy: Cluster, or keeping Local with an endpoint on every node).
IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
if [ -z "$IPS" ]; then
  echo "Couldn't read node IPs — is the cluster up? Wait and retry." >&2
  exit 1
fi
FAIL=0
for ip in $IPS; do
  CODE=$(curl -s --max-time 5 -o /dev/null -w '%{http_code}' "http://$ip:30080" 2>/dev/null)
  if [ "$CODE" != "200" ]; then
    echo "rtp-ingress NodePort still blackholes on node $ip (got '$CODE'). Set externalTrafficPolicy: Cluster, or give every node a local endpoint (e.g. a DaemonSet)." >&2
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] || exit 1
echo "✓ rtp-ingress NodePort answers on every node IP — reachability restored"
exit 0
