#!/bin/bash
# Checks: the cross-namespace path works — a client with sip-app's identity in
# app-services can now reach session-broker in media — which only happens if the
# allow's peer gained a namespaceSelector reaching across the boundary.
OUT=$(kubectl run bf02-verify --rm -i --restart=Never --labels app=sip-app \
  --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=8 http://session-broker.media/ 2>/dev/null)
if echo "$OUT" | grep -qi "nginx\|Welcome"; then
  echo "✓ sip-app (app-services) reaches session-broker (media) — the allow now crosses namespaces via a namespaceSelector"
  exit 0
fi
echo "sip-app still can't reach session-broker across namespaces. The allow's `from` peer needs a namespaceSelector for app-services (combined with the podSelector in one element = AND). Wait a few seconds after applying and retry." >&2
exit 1
