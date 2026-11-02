#!/bin/bash
# Checks: the deep link /index.html routes through the controller to portal-ui. Asserts
# the outcome (the path matches a rule), not a specific fix command. Prefix works, and
# so does any rule that matches /index.html.
OUT=$(kubectl run bf05-verify --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=8 --header "Host: portal.polyphone.example" \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/index.html 2>/dev/null)
if echo "$OUT" | grep -qi "nginx\|Welcome"; then
  echo "✓ /index.html routes to portal-ui: the rule's pathType now matches deep links"
  exit 0
fi
echo "/index.html still returns 404. The rule uses pathType Exact on /, which matches only /. Change pathType to Prefix, wait a few seconds and retry." >&2
exit 1
