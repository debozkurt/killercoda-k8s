#!/bin/bash
# Checks: sip-app Deployment exists, owns a ReplicaSet, and is satisfied (2/2).
OWNER=$(kubectl get rs -n app-services -l app=sip-app -o jsonpath='{.items[0].metadata.ownerReferences[0].name}' 2>/dev/null)
[ "$OWNER" = "sip-app" ] || { echo "ReplicaSet owner is '$OWNER', expected 'sip-app' (owner chain not intact)" >&2; exit 1; }

READY=$(kubectl get deploy sip-app -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "$READY" = "2" ] || { echo "sip-app has $READY/2 ready replicas; reconciliation may still be in flight — re-run in a few seconds" >&2; exit 1; }

echo "✓ Owner chain intact: Deployment/sip-app → ReplicaSet → Pods, 2/2 ready"
exit 0
