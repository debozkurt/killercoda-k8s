#!/bin/bash
# Checks: the Ingress routes end to end again. A request through the controller with
# the portal host returns portal-ui's nginx page instead of a 503. Asserts the outcome
# (traffic routes), not a specific fix command.
OUT=$(kubectl run bf03-verify --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=8 --header "Host: portal.polyphone.example" \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/ 2>/dev/null)
if echo "$OUT" | grep -qi "nginx\|Welcome"; then
  echo "✓ portal.polyphone.example routes to portal-ui again: the backend port matches the Service"
  exit 0
fi
echo "The Ingress still does not return the backend page. Point the rule's backend port at 80, the port portal-ui exposes. Wait a few seconds and retry." >&2
exit 1
