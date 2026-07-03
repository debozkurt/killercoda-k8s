#!/bin/bash
# Checks: both overlays render, and prod actually departs from lab where the
# overlay says it should — replicas (patch), image tag (transformer), config
# (generator merge), and nodeAffinity (component). Asserts the render diff.
DIR=/root/edge-relay

LAB=$(kubectl kustomize "$DIR/overlays/lab" 2>/dev/null)
PROD=$(kubectl kustomize "$DIR/overlays/prod" 2>/dev/null)
[ -n "$LAB" ]  || { echo "lab overlay did not render." >&2; exit 1; }
[ -n "$PROD" ] || { echo "prod overlay did not render." >&2; exit 1; }

echo "$LAB"  | grep -q 'replicas: 1' || { echo "lab should render replicas: 1." >&2; exit 1; }
echo "$PROD" | grep -q 'replicas: 3' || { echo "prod patch should set replicas: 3." >&2; exit 1; }
echo "$PROD" | grep -q 'image: nginx:1.27' || { echo "prod images transformer should pin nginx:1.27." >&2; exit 1; }
echo "$PROD" | grep -q 'MAX_SESSIONS: "5000"' || { echo "prod generator merge should set MAX_SESSIONS=5000." >&2; exit 1; }
echo "$PROD" | grep -q 'nodeAffinity' || { echo "prod should include the regional-affinity component (nodeAffinity)." >&2; exit 1; }
echo "$LAB"  | grep -q 'nodeAffinity' && { echo "lab should NOT include the component (no nodeAffinity)." >&2; exit 1; }

echo "✓ One base, two overlays: prod diverges via patch (3), image (1.27), config (5000), and component (nodeAffinity); lab stays lean."
exit 0
