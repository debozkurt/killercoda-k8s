#!/bin/bash
# Checks: the Ingress routes external HTTP end to end — a request with the matching
# Host header, sent to the controller, comes back with portal-ui's nginx page. Proves
# the controller claimed the object (class nginx) and forwarded to the backend Service.
CIP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CIP" ]; then
  echo "The ingress-nginx controller Service isn't up yet — it can take a couple of minutes to pull and start. Wait and retry." >&2
  exit 1
fi
OUT=$(kubectl run ing-verify --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=8 --header 'Host: portal.polyphone.example' "http://$CIP/" 2>/dev/null)
if echo "$OUT" | grep -qi "nginx\|Welcome"; then
  echo "✓ Ingress routes portal.polyphone.example to portal-ui — external HTTP reached the backend Service"
  exit 0
fi
echo "The Ingress didn't return the backend page yet (controller may still be starting, or the Ingress not claimed). Wait and retry." >&2
exit 1
