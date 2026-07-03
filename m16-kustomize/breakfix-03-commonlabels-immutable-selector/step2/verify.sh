#!/bin/bash
# Checks: the prod promotion landed (3 replicas, prod image) AND the fix kept the
# tier label OUT of the immutable selector (selector unchanged, tier on metadata).
NS=edge

READY=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" -ge 3 ] || { echo "prod promotion not landed yet (${READY:-0}/3). After the transformer swap: kubectl apply -k /root/edge-relay/overlays/prod" >&2; exit 1; }

IMG=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$IMG" = "nginx:1.27" ] || { echo "Expected the prod image nginx:1.27, got '$IMG' — did the prod overlay apply?" >&2; exit 1; }

# The selector must NOT carry tier (proves the label was kept off the immutable field)
SELTIER=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.selector.matchLabels.tier}' 2>/dev/null)
[ -z "$SELTIER" ] || { echo "spec.selector still carries tier='$SELTIER'. Use labels: with includeSelectors:false so the label stays off the selector." >&2; exit 1; }

# ...but tier=prod SHOULD be present as a metadata label
METATIER=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)
[ "$METATIER" = "prod" ] || { echo "Expected metadata label tier=prod on the Deployment, got '$METATIER'." >&2; exit 1; }

echo "✓ Promotion landed: edge-relay 3/3 on nginx:1.27, selector still {app: edge-relay}, tier=prod on metadata only."
exit 0
