#!/bin/bash
# Checks: the prod spec landed (3 ready, nginx:1.27), the selector is still
# app=edge-relay only, and tier=prod is a metadata label.
NS=edge
FIX="Replace commonLabels with labels: [{pairs: {tier: prod}, includeSelectors: false}] in overlays/prod, then:"
READY=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
IMG=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "${READY:-0}" -lt 3 ] || [ "$IMG" != "nginx:1.27" ]; then
  echo "edge-relay runs ${READY:-0} ready replicas of '$IMG'; prod is 3 of nginx:1.27." >&2
  echo "$FIX" >&2
  echo "  kubectl apply -k /root/edge-relay/overlays/prod" >&2
  exit 1
fi
SEL=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null)
if [ "$SEL" != '{"app":"edge-relay"}' ]; then
  echo "The Deployment selector is $SEL, not {\"app\":\"edge-relay\"}. The fix must not change the selector." >&2
  exit 1
fi
TIER=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)
if [ "$TIER" != "prod" ]; then
  echo "The Deployment label tier is '$TIER', not prod. $FIX" >&2
  echo "  kubectl apply -k /root/edge-relay/overlays/prod" >&2
  exit 1
fi
SVCSEL=$(kubectl get svc edge-relay -n "$NS" -o jsonpath='{.spec.selector}' 2>/dev/null)
EPS=$(kubectl get endpoints edge-relay -n "$NS" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ "$SVCSEL" != '{"app":"edge-relay"}' ] || [ -z "$EPS" ]; then
  echo "The Service selector is $SVCSEL with endpoints '$EPS'; it must be {\"app\":\"edge-relay\"} with Pod addresses. Apply the fixed overlay:" >&2
  echo "  kubectl apply -k /root/edge-relay/overlays/prod" >&2
  exit 1
fi
echo "✓ Prod landed: edge-relay 3/3 on nginx:1.27, selector app=edge-relay, label tier=prod, Service has endpoints"
exit 0
