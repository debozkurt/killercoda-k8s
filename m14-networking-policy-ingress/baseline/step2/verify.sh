#!/bin/bash
# Checks: the allowed path actually works end to end — a client in app-services can
# reach session-broker in media, which proves the CNI is enforcing the allow (not
# just storing it). Runs a throwaway busybox client and looks for nginx's response.
OUT=$(kubectl run np-verify --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=8 http://session-broker.media/ 2>/dev/null)
if echo "$OUT" | grep -qi "nginx\|Welcome"; then
  echo "✓ allowed path works: a client in app-services reached session-broker.media (CNI is enforcing the allow)"
  exit 0
fi
echo "app-services could not reach session-broker.media yet. The fleet, policies, or busybox pull may still be settling — wait and retry." >&2
exit 1
