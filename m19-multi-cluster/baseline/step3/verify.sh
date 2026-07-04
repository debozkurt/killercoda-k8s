#!/bin/bash
# Checks the promotion state: 1.27 has been promoted through lab and stage, prod
# still inherits the base default 1.25, and the base carries no images: transformer
# (so the per-tier rollout stays in the leaves — blast radius matches intent).
FLEET=/root/fleet

LAB=$(kubectl kustomize "$FLEET/clusters/lab-us-east-1" 2>/dev/null | grep -m1 'image: nginx')
STG=$(kubectl kustomize "$FLEET/clusters/stage-us-east-1" 2>/dev/null | grep -m1 'image: nginx')
PRD=$(kubectl kustomize "$FLEET/clusters/prod-us-east-1" 2>/dev/null | grep -m1 'image: nginx')

echo "$LAB" | grep -q '1.27' || { echo "lab-us-east-1 should render the promoted image nginx:1.27." >&2; exit 1; }
echo "$STG" | grep -q '1.27' || { echo "stage-us-east-1 should render the promoted image nginx:1.27." >&2; exit 1; }
echo "$PRD" | grep -q '1.25' || { echo "prod-us-east-1 should still render the base default nginx:1.25 (not yet promoted)." >&2; exit 1; }

if grep -rqs 'images:' "$FLEET/base/"; then
  echo "The base carries an images: transformer — a per-tier image pin does not belong in the base (fleet-wide blast radius)." >&2
  exit 1
fi

echo "✓ Promotion state correct: 1.27 through lab+stage, prod on 1.25; no image pin in the base."
exit 0
