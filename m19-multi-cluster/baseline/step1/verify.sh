#!/bin/bash
# Checks: the fleet tree exists and prod-us-east-1 renders as the composed path
# base -> regions/us-east-1 -> leaf: REGION from the region layer, replicas from
# the leaf patch, and the Deployment reference rewritten to the hashed ConfigMap.
FLEET=/root/fleet

[ -f "$FLEET/base/kustomization.yaml" ] || { echo "No base kustomization at $FLEET/base — is the fleet repo present?" >&2; exit 1; }

RENDER=$(kubectl kustomize "$FLEET/clusters/prod-us-east-1" 2>/dev/null)
[ -n "$RENDER" ] || { echo "kubectl kustomize clusters/prod-us-east-1 produced no output — does it render?" >&2; exit 1; }

echo "$RENDER" | grep -q 'REGION: us-east-1' || { echo "prod-us-east-1 should inherit REGION: us-east-1 from its region overlay." >&2; exit 1; }
echo "$RENDER" | grep -q 'replicas: 3'       || { echo "prod-us-east-1 should render replicas: 3 (the leaf patch)." >&2; exit 1; }

CM=$(echo "$RENDER" | grep -oE 'edge-relay-config-[a-z0-9]+' | head -1)
[ -n "$CM" ] || { echo "No hash-suffixed ConfigMap (edge-relay-config-<hash>) in the render." >&2; exit 1; }
echo "$RENDER" | grep -q "name: $CM" || { echo "The Deployment reference was not rewritten to the hashed ConfigMap ($CM)." >&2; exit 1; }

echo "✓ Fleet tree present; prod-us-east-1 renders the composed path (REGION us-east-1, replicas 3, ConfigMap $CM)."
exit 0
