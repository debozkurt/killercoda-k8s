#!/bin/bash
# Checks: the Ingress routes end to end again — a request through the controller with
# the portal host returns portal-ui's nginx page instead of a 503. Asserts the outcome
# (traffic routes), not a specific fix command.
CIP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CIP" ]; then
  echo "The ingress-nginx controller Service isn't up yet — wait and retry." >&2
  exit 1
fi
OUT=$(kubectl run bf03-verify --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=8 --header "Host: portal.polyphone.example" "http://$CIP/" 2>/dev/null)
if echo "$OUT" | grep -qi "nginx\|Welcome"; then
  echo "✓ portal.polyphone.example routes to portal-ui again — the backend port matches the Service (no more 503)"
  exit 0
fi
echo "The Ingress still isn't returning the backend page. Point the rule's backend.service.port at 80 (the port portal-ui exposes), then wait a few seconds and retry." >&2
exit 1
