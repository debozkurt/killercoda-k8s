#!/bin/bash
# Checks: the values file uses the key the chart reads, the release was
# upgraded from it (the stray key is gone from the release values), and the
# Deployment runs 3 Pods that the rendered manifest asks for.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

F=/root/voicemail-values.yaml
grep -q '^replicaCount: 3' "$F" && ! grep -q '^replicas:' "$F" \
  || { echo "$F must set replicaCount: 3 and no replicas key. Fix the file, then helm upgrade -f $F" >&2; exit 1; }

helm get values voicemail -n app-services 2>/dev/null | grep -q '^replicas:' \
  && { echo "The release still stores the unused replicas key. Run: helm upgrade voicemail /root/voicemail -n app-services -f $F" >&2; exit 1; }

helm get manifest voicemail -n app-services 2>/dev/null | grep -q '^  replicas: 3$' \
  || { echo "The release manifest does not render replicas: 3. Run: helm upgrade voicemail /root/voicemail -n app-services -f $F" >&2; exit 1; }

READY=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" -ge 3 ] || { echo "Expected 3 ready voicemail Pods, got ${READY:-0}. Wait a few seconds and check again." >&2; exit 1; }

echo "✓ Values file fixed: replicaCount reached the manifest, voicemail runs $READY ready Pods"
exit 0
