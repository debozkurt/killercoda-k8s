#!/bin/bash
# Checks: the route no longer targets the empty 'canary' subset and callers reach
# session-broker again (HTTP 200). Asserts the outcome (traffic flows), not the exact edit.
SUBSET=$(kubectl get virtualservice session-broker -n media \
  -o jsonpath='{.spec.http[0].route[0].destination.subset}' 2>/dev/null)
if [ "$SUBSET" = "canary" ]; then
  echo "The route still points at subset 'canary', which has no pods. Point it at 'stable'" >&2
  echo "(or deploy pods labeled version=canary) and retry." >&2
  exit 1
fi
CODE=$(kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w '%{http_code}' --max-time 6 http://session-broker.media/ 2>/dev/null)
if [ "$CODE" = "200" ]; then
  echo "✓ route now targets a subset with pods (subset='$SUBSET'); mesh-client gets HTTP 200"
  exit 0
fi
echo "route subset is '$SUBSET' but callers still get HTTP '$CODE' (expected 200) — the config push" >&2
echo "may still be in flight; check 'istioctl proxy-config routes' and retry." >&2
exit 1
