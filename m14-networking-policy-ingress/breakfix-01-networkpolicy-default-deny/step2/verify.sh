#!/bin/bash
# Checks: the legitimate intra-namespace path is restored — a client in media can
# reach session-broker again — AND the default-deny is still in place (isolation kept).
# Asserts the outcome (traffic flows), not a specific fix command.
if ! kubectl get networkpolicy default-deny-ingress -n media >/dev/null 2>&1; then
  echo "The default-deny-ingress policy is gone. Don't delete the deny — add an allow beside it so the namespace stays isolated." >&2
  exit 1
fi
OUT=$(kubectl run bf01-verify --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=8 http://session-broker.media/ 2>/dev/null)
if echo "$OUT" | grep -qi "nginx\|Welcome"; then
  echo "✓ session-broker reachable from within media again, and the default-deny is still present (allow added, not removed)"
  exit 0
fi
echo "session-broker is still unreachable from media. Add an ingress allow that selects app=session-broker and permits from the media namespace (podSelector: {}). Wait a few seconds after applying and retry." >&2
exit 1
